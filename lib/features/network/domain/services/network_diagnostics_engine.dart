import '../datasources/network_probe_datasource.dart';
import '../entities/gaming_network_verdict.dart';
import '../entities/network_connection_type.dart';
import '../entities/network_diagnostic_session.dart';
import '../entities/network_metrics.dart';
import '../entities/network_recommendation.dart';

/// Core diagnostic engine that evaluates real-time gaming network quality,
/// calculates jitter and packet loss, and provides factual, conditional advice.
class NetworkDiagnosticsEngine {
  const NetworkDiagnosticsEngine(this._probeSource);

  final NetworkProbeDataSource _probeSource;

  /// Runs full gaming network diagnostics non-aggressively.
  /// Does NOT perform high-bandwidth download/upload tests automatically.
  Future<NetworkDiagnosticSession> runDiagnostics({
    String targetHost = '1.1.1.1',
    int targetPort = 53,
    int probeCount = 8,
    void Function(String stepDescription)? onProgress,
  }) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    // ── 1. Connection Type ──────────────────────────────────────────────────
    onProgress?.call('Detecting connection type...');
    final connType = await _probeSource.getConnectionType();
    final interfaceDetails = await _probeSource.getInterfaceDetails();

    if (connType == NetworkConnectionType.offline) {
      stopwatch.stop();
      final metrics = NetworkMetrics(
        connectionType: connType,
        isOnline: false,
        packetLossPercent: 100.0,
        probeSamplesCount: 0,
        timestamp: startTime,
      );
      return NetworkDiagnosticSession(
        id: 'net_diag_${startTime.millisecondsSinceEpoch}',
        timestamp: startTime,
        metrics: metrics,
        primaryVerdict: GamingNetworkVerdict.networkUnavailable,
        recommendations: const [
          NetworkRecommendation(
            title: 'No Active Connection',
            detail: 'Your device is not connected to Wi-Fi, mobile data, or Ethernet. Connect to a network to test gaming connectivity.',
            severity: RecommendationSeverity.critical,
          ),
        ],
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }

    // ── 2. DNS Resolution Timing ────────────────────────────────────────────
    onProgress?.call('Testing DNS resolution speed...');
    final dnsDuration = await _probeSource.measureDnsResolution('dns.google');

    // ── 3. Gateway Latency (if available) ───────────────────────────────────
    final gatewayIp = interfaceDetails['gatewayIp'] as String?;
    double? gatewayLatency;
    if (gatewayIp != null && gatewayIp.isNotEmpty) {
      onProgress?.call('Pinging local gateway...');
      gatewayLatency = await _probeSource.probeGatewayLatency(gatewayIp);
    }

    // ── 4. Multi-Sample Latency Probes ──────────────────────────────────────
    onProgress?.call('Measuring packet latency and jitter...');
    final samples = await _probeSource.probeLatencySamples(
      targetHost,
      targetPort,
      count: probeCount,
    );

    stopwatch.stop();

    // ── 5. Statistical Calculations ─────────────────────────────────────────
    final validSamples = samples.whereType<double>().toList();
    final droppedCount = samples.length - validSamples.length;
    final packetLoss = samples.isEmpty
        ? 0.0
        : (droppedCount / samples.length) * 100.0;

    double? medianLatency;
    double? minLatency;
    double? maxLatency;
    double? jitter;

    if (validSamples.isNotEmpty) {
      // ── Jitter: computed BEFORE sorting, on original probe-arrival order ───
      // RFC 3550 / IETF definition: mean absolute difference of consecutive RTTs
      if (validSamples.length > 1) {
        double diffSum = 0.0;
        for (int i = 0; i < validSamples.length - 1; i++) {
          diffSum += (validSamples[i + 1] - validSamples[i]).abs();
        }
        jitter = diffSum / (validSamples.length - 1);
      } else {
        jitter = 0.0;
      }

      // ── Sort for min / median / max ─────────────────────────────────────────
      validSamples.sort();
      minLatency = validSamples.first;
      maxLatency = validSamples.last;
      medianLatency = validSamples[validSamples.length ~/ 2];
    }

    final isOnline = validSamples.isNotEmpty || (dnsDuration != null && dnsDuration > 0);

    final metrics = NetworkMetrics(
      connectionType: connType,
      isOnline: isOnline,
      dnsResolutionMs: dnsDuration,
      latencyMs: medianLatency,
      minLatencyMs: minLatency,
      maxLatencyMs: maxLatency,
      jitterMs: jitter,
      packetLossPercent: packetLoss,
      probeSamplesCount: samples.length,
      timestamp: startTime,
      wifiFrequencyMhz: interfaceDetails['wifiFrequencyMhz'] as int?,
      wifiLinkSpeedMbps: interfaceDetails['wifiLinkSpeedMbps'] as int?,
      localGatewayLatencyMs: gatewayLatency,
    );

    // ── 6. Verdict Classification ───────────────────────────────────────────
    final (primaryVerdict, secondaryVerdicts) = _classifyVerdicts(metrics);

    // ── 7. Formulate Factual, Conditional Recommendations ───────────────────
    final recommendations = _generateRecommendations(metrics, primaryVerdict);

    return NetworkDiagnosticSession(
      id: 'net_diag_${startTime.millisecondsSinceEpoch}',
      timestamp: startTime,
      metrics: metrics,
      primaryVerdict: primaryVerdict,
      secondaryVerdicts: secondaryVerdicts,
      recommendations: recommendations,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Classifies network quality into transparent gamer verdicts.
  (GamingNetworkVerdict, List<GamingNetworkVerdict>) _classifyVerdicts(NetworkMetrics m) {
    if (!m.isOnline || m.latencyMs == null) {
      return (GamingNetworkVerdict.networkUnavailable, []);
    }

    final secondaries = <GamingNetworkVerdict>[];

    // Check packet loss
    if (m.packetLossPercent > 0.0) {
      secondaries.add(GamingNetworkVerdict.packetLossDetected);
    }

    // Check jitter
    if (m.jitterMs != null && m.jitterMs! >= 18.0) {
      secondaries.add(GamingNetworkVerdict.highJitter);
    }

    // Check latency instability
    if (m.minLatencyMs != null && m.maxLatencyMs != null) {
      if ((m.maxLatencyMs! - m.minLatencyMs!) >= 45.0) {
        secondaries.add(GamingNetworkVerdict.unstableLatency);
      }
    }

    // Determine primary verdict
    GamingNetworkVerdict primary;
    if (m.packetLossPercent >= 15.0) {
      primary = GamingNetworkVerdict.packetLossDetected;
    } else if (m.jitterMs != null && m.jitterMs! >= 20.0) {
      primary = GamingNetworkVerdict.highJitter;
    } else if (secondaries.contains(GamingNetworkVerdict.highJitter)) {
      primary = GamingNetworkVerdict.highJitter;
    } else if (m.latencyMs! > 95.0) {
      primary = GamingNetworkVerdict.highLatency;
    } else if (secondaries.contains(GamingNetworkVerdict.unstableLatency)) {
      primary = GamingNetworkVerdict.unstableLatency;
    } else if (secondaries.contains(GamingNetworkVerdict.packetLossDetected)) {
      primary = GamingNetworkVerdict.packetLossDetected;
    } else if (m.latencyMs! <= 40.0 && (m.jitterMs ?? 0) <= 8.0 && m.packetLossPercent == 0.0) {
      primary = GamingNetworkVerdict.lowLatency;
    } else {
      primary = GamingNetworkVerdict.moderateLatency;
    }

    secondaries.remove(primary);
    return (primary, secondaries);
  }

  /// Generates factual and conditional recommendations.
  /// Never claims ISP is at fault without verified evidence ruling out the local network.
  List<NetworkRecommendation> _generateRecommendations(
    NetworkMetrics m,
    GamingNetworkVerdict verdict,
  ) {
    final list = <NetworkRecommendation>[];

    if (!m.isOnline) {
      list.add(const NetworkRecommendation(
        title: 'Check Connection State',
        detail: 'External servers could not be reached. Ensure airplane mode is off and Wi-Fi/cellular connection is active.',
        severity: RecommendationSeverity.critical,
      ));
      return list;
    }

    // Wi-Fi 2.4 GHz vs 5 GHz recommendation
    if (m.connectionType == NetworkConnectionType.wifi && m.wifiFrequencyMhz != null) {
      if (m.wifiFrequencyMhz! < 3000) {
        list.add(NetworkRecommendation(
          title: 'Switch to 5GHz or 6GHz Wi-Fi Band',
          detail: 'Your device is connected to a 2.4GHz Wi-Fi channel. 2.4GHz channels are narrow and easily congested by household appliances and Bluetooth, which directly contributes to jitter.',
          severity: RecommendationSeverity.warning,
          evidence: 'Frequency: ${m.wifiFrequencyMhz} MHz (2.4 GHz band)',
        ));
      }
    }

    // Packet loss attribution
    if (m.packetLossPercent > 0.0) {
      if (m.localGatewayLatencyMs != null && m.localGatewayLatencyMs! < 10.0) {
        list.add(NetworkRecommendation(
          title: 'Upstream Packet Loss Detected',
          detail: 'Your local connection to your router is healthy (${m.localGatewayLatencyMs!.toStringAsFixed(1)}ms), but packets were lost beyond the local gateway. This points to external routing or upstream ISP line congestion rather than device Wi-Fi signal.',
          severity: RecommendationSeverity.critical,
          evidence: 'Local hop: ${m.localGatewayLatencyMs!.toStringAsFixed(1)}ms | Packet loss: ${m.packetLossPercent.toStringAsFixed(1)}%',
        ));
      } else if (m.connectionType == NetworkConnectionType.wifi) {
        list.add(NetworkRecommendation(
          title: 'Local Wi-Fi Packet Loss',
          detail: 'Packet drops may be caused by weak Wi-Fi signal or router queuing. Moving closer to the wireless access point or restarting the router can stabilize packet delivery.',
          severity: RecommendationSeverity.warning,
          evidence: 'Observed loss: ${m.packetLossPercent.toStringAsFixed(1)}%',
        ));
      }
    }

    // Jitter recommendation
    if (m.jitterMs != null && m.jitterMs! >= 15.0) {
      list.add(NetworkRecommendation(
        title: 'Bufferbloat / Network Congestion Likely',
        detail: 'Jitter exceeding 15ms indicates packets are queuing inconsistently. Ensure other devices on the same network are not downloading large files, torrenting, or streaming 4K video during competitive matches.',
        severity: RecommendationSeverity.warning,
        evidence: 'Measured jitter: ${m.jitterMs!.toStringAsFixed(1)}ms',
      ));
    }

    // High DNS resolution time
    if (m.dnsResolutionMs != null && m.dnsResolutionMs! > 120.0) {
      list.add(NetworkRecommendation(
        title: 'Slow DNS Lookup Time',
        detail: 'DNS hostname resolution took ${m.dnsResolutionMs!.toStringAsFixed(0)}ms. While match gameplay packets use direct IP addresses, matchmaking and game asset loading may feel sluggish.',
        severity: RecommendationSeverity.info,
        evidence: 'DNS lookup: ${m.dnsResolutionMs!.toStringAsFixed(0)}ms',
      ));
    }

    // Cellular data advisory
    if (m.connectionType == NetworkConnectionType.cellular) {
      list.add(const NetworkRecommendation(
        title: 'Mobile Cellular Connection',
        detail: 'Mobile network ping naturally varies depending on tower handoff, physical obstacles, and carrier traffic prioritization. Low-latency 5GHz Wi-Fi usually delivers more consistent frame delivery.',
        severity: RecommendationSeverity.info,
      ));
    }

    // Low latency positive summary
    if (verdict == GamingNetworkVerdict.lowLatency && list.isEmpty) {
      list.add(NetworkRecommendation(
        title: 'Optimal Competitive Connection',
        detail: 'Your latency is low (${m.latencyDisplay}) with zero packet loss and minimal jitter (${m.jitterDisplay}). Network conditions are ideal for competitive multiplayer play.',
        severity: RecommendationSeverity.positive,
        evidence: 'Ping: ${m.latencyDisplay} | Jitter: ${m.jitterDisplay} | Loss: 0%',
      ));
    }

    return list;
  }
}

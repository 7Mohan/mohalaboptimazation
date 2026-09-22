import 'network_connection_type.dart';

/// Telemetry metrics captured during a gaming network diagnostic probe.
class NetworkMetrics {
  const NetworkMetrics({
    required this.connectionType,
    required this.isOnline,
    this.dnsResolutionMs,
    this.latencyMs,
    this.minLatencyMs,
    this.maxLatencyMs,
    this.jitterMs,
    this.packetLossPercent = 0.0,
    this.probeSamplesCount = 0,
    required this.timestamp,
    this.wifiFrequencyMhz,
    this.wifiLinkSpeedMbps,
    this.localGatewayLatencyMs,
  });

  /// The active network transport during the test.
  final NetworkConnectionType connectionType;

  /// Whether external servers were reachable.
  final bool isOnline;

  /// Time taken to resolve hostnames via DNS in milliseconds.
  final double? dnsResolutionMs;

  /// Median round-trip time to target game endpoints in milliseconds.
  final double? latencyMs;

  /// Minimum observed round-trip time in milliseconds.
  final double? minLatencyMs;

  /// Maximum observed round-trip time in milliseconds.
  final double? maxLatencyMs;

  /// Jitter: mean absolute difference between consecutive latency samples in milliseconds.
  final double? jitterMs;

  /// Percentage of probe packets that timed out or failed (0.0 to 100.0).
  final double packetLossPercent;

  /// Number of distinct packet probes dispatched.
  final int probeSamplesCount;

  /// Timestamp when the metrics were recorded.
  final DateTime timestamp;

  /// Wi-Fi channel frequency in MHz (e.g. ~2400 for 2.4 GHz, ~5000 for 5 GHz).
  final int? wifiFrequencyMhz;

  /// Link speed reported by Wi-Fi interface in Mbps.
  final int? wifiLinkSpeedMbps;

  /// Round-trip time to the local router/gateway in milliseconds (if measurable).
  final double? localGatewayLatencyMs;

  // ---------------------------------------------------------------------------
  // Display helpers
  // ---------------------------------------------------------------------------

  String get latencyDisplay {
    if (latencyMs == null) return 'Unavailable';
    return '${latencyMs!.toStringAsFixed(0)} ms';
  }

  String get jitterDisplay {
    if (jitterMs == null) return 'Unavailable';
    return '${jitterMs!.toStringAsFixed(1)} ms';
  }

  String get packetLossDisplay {
    return '${packetLossPercent.toStringAsFixed(1)}%';
  }

  String get dnsDisplay {
    if (dnsResolutionMs == null) return 'Unavailable';
    return '${dnsResolutionMs!.toStringAsFixed(0)} ms';
  }

  String? get wifiBandDisplay {
    if (wifiFrequencyMhz == null) return null;
    if (wifiFrequencyMhz! >= 5925) return '6.0 GHz';
    if (wifiFrequencyMhz! >= 4900) return '5.0 GHz';
    if (wifiFrequencyMhz! >= 2400) return '2.4 GHz';
    return null;
  }

  Map<String, dynamic> toMap() => {
        'connectionType': connectionType.name,
        'isOnline': isOnline,
        'dnsResolutionMs': dnsResolutionMs,
        'latencyMs': latencyMs,
        'minLatencyMs': minLatencyMs,
        'maxLatencyMs': maxLatencyMs,
        'jitterMs': jitterMs,
        'packetLossPercent': packetLossPercent,
        'probeSamplesCount': probeSamplesCount,
        'timestamp': timestamp.toIso8601String(),
        'wifiFrequencyMhz': wifiFrequencyMhz,
        'wifiLinkSpeedMbps': wifiLinkSpeedMbps,
        'localGatewayLatencyMs': localGatewayLatencyMs,
      };

  factory NetworkMetrics.fromMap(Map<String, dynamic> map) {
    return NetworkMetrics(
      connectionType: NetworkConnectionType.values.firstWhere(
        (t) => t.name == map['connectionType'],
        orElse: () => NetworkConnectionType.unknown,
      ),
      isOnline: map['isOnline'] as bool? ?? false,
      dnsResolutionMs: (map['dnsResolutionMs'] as num?)?.toDouble(),
      latencyMs: (map['latencyMs'] as num?)?.toDouble(),
      minLatencyMs: (map['minLatencyMs'] as num?)?.toDouble(),
      maxLatencyMs: (map['maxLatencyMs'] as num?)?.toDouble(),
      jitterMs: (map['jitterMs'] as num?)?.toDouble(),
      packetLossPercent: (map['packetLossPercent'] as num?)?.toDouble() ?? 0.0,
      probeSamplesCount: map['probeSamplesCount'] as int? ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      wifiFrequencyMhz: map['wifiFrequencyMhz'] as int?,
      wifiLinkSpeedMbps: map['wifiLinkSpeedMbps'] as int?,
      localGatewayLatencyMs: (map['localGatewayLatencyMs'] as num?)?.toDouble(),
    );
  }
}

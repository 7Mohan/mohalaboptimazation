import 'gaming_network_verdict.dart';
import 'network_metrics.dart';
import 'network_recommendation.dart';

/// A completed gaming network diagnostic session, including metrics, verdicts, and recommendations.
class NetworkDiagnosticSession {
  const NetworkDiagnosticSession({
    required this.id,
    required this.timestamp,
    required this.metrics,
    required this.primaryVerdict,
    this.secondaryVerdicts = const [],
    this.recommendations = const [],
    required this.durationMs,
  });

  final String id;
  final DateTime timestamp;
  final NetworkMetrics metrics;
  final GamingNetworkVerdict primaryVerdict;
  final List<GamingNetworkVerdict> secondaryVerdicts;
  final List<NetworkRecommendation> recommendations;
  final int durationMs;

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'metrics': metrics.toMap(),
        'primaryVerdict': primaryVerdict.name,
        'secondaryVerdicts': secondaryVerdicts.map((v) => v.name).toList(),
        'recommendations': recommendations.map((r) => r.toMap()).toList(),
        'durationMs': durationMs,
      };

  factory NetworkDiagnosticSession.fromMap(Map<String, dynamic> map) {
    return NetworkDiagnosticSession(
      id: map['id'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      metrics: NetworkMetrics.fromMap(map['metrics'] as Map<String, dynamic>? ?? {}),
      primaryVerdict: GamingNetworkVerdict.values.firstWhere(
        (v) => v.name == map['primaryVerdict'],
        orElse: () => GamingNetworkVerdict.networkUnavailable,
      ),
      secondaryVerdicts: (map['secondaryVerdicts'] as List<dynamic>? ?? [])
          .map((v) => GamingNetworkVerdict.values.firstWhere(
                (val) => val.name == v,
                orElse: () => GamingNetworkVerdict.networkUnavailable,
              ))
          .toList(),
      recommendations: (map['recommendations'] as List<dynamic>? ?? [])
          .map((r) => NetworkRecommendation.fromMap(r as Map<String, dynamic>))
          .toList(),
      durationMs: map['durationMs'] as int? ?? 0,
    );
  }
}

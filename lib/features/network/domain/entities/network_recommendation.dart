import 'package:flutter/material.dart';

enum RecommendationSeverity {
  positive(Icons.check_circle_outline_rounded, Colors.green),
  info(Icons.info_outline_rounded, Colors.blue),
  warning(Icons.warning_amber_rounded, Colors.orange),
  critical(Icons.error_outline_rounded, Colors.red);

  const RecommendationSeverity(this.icon, this.color);
  final IconData icon;
  final Color color;
}

/// A factual, conditional recommendation derived from measured network telemetry.
class NetworkRecommendation {
  const NetworkRecommendation({
    required this.title,
    required this.detail,
    required this.severity,
    this.evidence,
  });

  /// Clear, concise headline.
  final String title;

  /// Factual, conditional explanation of what was observed and what can help.
  final String detail;

  /// Severity level of the observation.
  final RecommendationSeverity severity;

  /// Concrete data point backing the observation (e.g. "Observed 22ms jitter on 2.4GHz").
  final String? evidence;

  Map<String, dynamic> toMap() => {
        'title': title,
        'detail': detail,
        'severity': severity.name,
        'evidence': evidence,
      };

  factory NetworkRecommendation.fromMap(Map<String, dynamic> map) {
    return NetworkRecommendation(
      title: map['title'] as String? ?? '',
      detail: map['detail'] as String? ?? '',
      severity: RecommendationSeverity.values.firstWhere(
        (s) => s.name == map['severity'],
        orElse: () => RecommendationSeverity.info,
      ),
      evidence: map['evidence'] as String?,
    );
  }

  @override
  String toString() => 'NetworkRecommendation($title, severity: ${severity.name})';
}

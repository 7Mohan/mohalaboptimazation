import 'package:flutter/material.dart';

/// Evaluates network telemetry into clear, gamer-focused interpretations.
enum GamingNetworkVerdict {
  lowLatency(
    'Low Latency',
    'Optimal for fast-paced competitive gaming. Ping is low with minimal variance.',
    Icons.verified_rounded,
    Colors.green,
  ),
  moderateLatency(
    'Moderate Latency',
    'Playable for most multiplayer games, though minor input delay may be perceptible.',
    Icons.check_circle_outline_rounded,
    Colors.teal,
  ),
  highLatency(
    'High Latency',
    'High round-trip time. Actions and player positions will feel delayed.',
    Icons.timelapse_rounded,
    Colors.amber,
  ),
  unstableLatency(
    'Unstable Latency',
    'Latency fluctuates heavily. You may experience random lag spikes.',
    Icons.show_chart_rounded,
    Colors.orange,
  ),
  highJitter(
    'High Jitter',
    'Packet delivery timing varies significantly, causing stuttering and rubberbanding.',
    Icons.graphic_eq_rounded,
    Colors.deepOrange,
  ),
  packetLossDetected(
    'Packet Loss Detected',
    'Packets were dropped in transit. May cause missed shots, teleporting, or disconnects.',
    Icons.warning_amber_rounded,
    Colors.redAccent,
  ),
  networkUnavailable(
    'Network Unavailable',
    'No connection could be established to external game servers or DNS.',
    Icons.signal_wifi_connected_no_internet_4_rounded,
    Colors.grey,
  );

  const GamingNetworkVerdict(
    this.title,
    this.description,
    this.icon,
    this.color,
  );

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

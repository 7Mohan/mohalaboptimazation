import 'package:flutter/material.dart';

/// Represents the physical or logical network connection transport.
enum NetworkConnectionType {
  wifi(
    'Wi-Fi',
    Icons.wifi_rounded,
    'Wireless Local Area Network',
    isSuitableForGaming: true,
  ),
  cellular(
    'Mobile Data',
    Icons.signal_cellular_alt_rounded,
    'Cellular Network Connection (4G/5G/LTE)',
    isSuitableForGaming: true,
  ),
  ethernet(
    'Ethernet',
    Icons.settings_ethernet_rounded,
    'Wired Ethernet Connection',
    isSuitableForGaming: true,
  ),
  vpn(
    'VPN Active',
    Icons.vpn_key_rounded,
    'Virtual Private Network Tunnel',
    isSuitableForGaming: false,
  ),
  offline(
    'Offline',
    Icons.signal_wifi_off_rounded,
    'No active network connectivity detected',
    isSuitableForGaming: false,
  ),
  unknown(
    'Unknown',
    Icons.device_unknown_rounded,
    'Connection transport could not be determined',
    isSuitableForGaming: false,
  );

  const NetworkConnectionType(
    this.displayName,
    this.icon,
    this.description, {
    required this.isSuitableForGaming,
  });

  final String displayName;
  final IconData icon;
  final String description;
  final bool isSuitableForGaming;
}

import '../entities/network_connection_type.dart';

/// Contract for probing real network connection properties and timing.
abstract class NetworkProbeDataSource {
  /// Detects the active physical/logical network connection transport.
  Future<NetworkConnectionType> getConnectionType();

  /// Reads interface metadata such as Wi-Fi band frequency (MHz), link speed (Mbps), and gateway IP.
  Future<Map<String, dynamic>> getInterfaceDetails();

  /// Measures hostname resolution duration via DNS in milliseconds.
  /// Returns null if DNS resolution fails.
  Future<double?> measureDnsResolution(String hostname);

  /// Dispatches [count] sequential TCP/socket probes to [host]:[port],
  /// measuring RTT in milliseconds for each.
  /// Timed out or dropped probes return null.
  Future<List<double?>> probeLatencySamples(
    String host,
    int port, {
    int count = 8,
    Duration timeout = const Duration(milliseconds: 1500),
  });

  /// Measures round-trip time to the local network gateway/router in milliseconds.
  Future<double?> probeGatewayLatency(String? gatewayIp);
}

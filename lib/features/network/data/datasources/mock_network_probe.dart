import '../../domain/datasources/network_probe_datasource.dart';
import '../../domain/entities/network_connection_type.dart';

/// In-memory mock for [NetworkProbeDataSource] enabling deterministic testing
/// across Wi-Fi, cellular, offline, DNS failure, high jitter, and packet loss scenarios.
class MockNetworkProbe implements NetworkProbeDataSource {
  MockNetworkProbe({
    this.connectionType = NetworkConnectionType.wifi,
    this.interfaceDetails = const {
      'wifiFrequencyMhz': 5180,
      'wifiLinkSpeedMbps': 866,
      'gatewayIp': '192.168.1.1',
    },
    this.dnsResolutionDurationMs = 18.5,
    this.samples = const [24.0, 25.0, 26.0, 24.5, 25.5, 24.8, 25.2, 24.9],
    this.gatewayLatencyMs = 2.4,
  });

  NetworkConnectionType connectionType;
  Map<String, dynamic> interfaceDetails;
  double? dnsResolutionDurationMs;
  List<double?> samples;
  double? gatewayLatencyMs;

  @override
  Future<NetworkConnectionType> getConnectionType() async => connectionType;

  @override
  Future<Map<String, dynamic>> getInterfaceDetails() async => Map.from(interfaceDetails);

  @override
  Future<double?> measureDnsResolution(String hostname) async => dnsResolutionDurationMs;

  @override
  Future<List<double?>> probeLatencySamples(
    String host,
    int port, {
    int count = 8,
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    return List.from(samples);
  }

  @override
  Future<double?> probeGatewayLatency(String? gatewayIp) async => gatewayLatencyMs;
}

import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/speaker.dart';

class DiscoveryService {
  static const String _serviceType = '_soundtouch._tcp.local';

  Future<List<Speaker>> discover({Duration timeout = const Duration(seconds: 5)}) async {
    final MDnsClient client = MDnsClient(rawDatagramSocketFactory: (
      dynamic host,
      int port, {
      bool? reuseAddress,
      bool? reusePort,
      int? ttl,
    }) =>
        RawDatagramSocket.bind(host, port,
            reuseAddress: true, reusePort: false, ttl: ttl ?? 1));

    final List<Speaker> results = <Speaker>[];

    try {
      await client.start();
      final stopwatch = Stopwatch()..start();

      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(_serviceType))
          .timeout(timeout, onTimeout: (sink) => sink.close())) {
        if (stopwatch.elapsed > timeout) break;
        await for (final SrvResourceRecord srv in client
            .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))
            .timeout(const Duration(seconds: 2),
                onTimeout: (sink) => sink.close())) {
          await for (final IPAddressResourceRecord ip in client
              .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target))
              .timeout(const Duration(seconds: 2),
                  onTimeout: (sink) => sink.close())) {
            final speaker = Speaker(
              name: _stripServiceSuffix(ptr.domainName),
              host: ip.address.address,
              port: srv.port,
            );
            if (!results.contains(speaker)) {
              results.add(speaker);
            }
            break;
          }
        }
      }
    } finally {
      client.stop();
    }

    return results;
  }

  String _stripServiceSuffix(String fullName) {
    final idx = fullName.indexOf('.$_serviceType');
    if (idx > 0) return fullName.substring(0, idx);
    return fullName;
  }
}

import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/utils/typedefs.dart';

abstract class HostRepository {
  const HostRepository();

  ResultFuture<List<Host>> getHosts();
  ResultFuture<int> addHost({
    required Host host,
    required String secret,
    String? passphrase,
  });

  ResultFuture<void> update({
    required Host host,
    String? secret,
    String? passphrase,
  });

  ResultFuture<void> delete(int hostId);

  ResultFuture<Host> pingHost({
    required Host host,
    Duration timeout = const Duration(seconds: 3),
  });

  ResultFuture<List<Host>> pingAllHosts({
    required List<Host> host,
    Duration timeout = const Duration(seconds: 3),
  });
}

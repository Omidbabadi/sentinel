import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/hosts/domain/repositories/host_repository.dart';

class PingAllHost extends UsecaseWithParams<List<Host>, PingAlHostParams> {
  const PingAllHost(this._repository);
  final HostRepository _repository;

  @override
  ResultFuture<List<Host>> call(PingAlHostParams params) =>
      _repository.pingAllHosts(host: params.host, timeout: params.timeout);
}

class PingAlHostParams {
  const PingAlHostParams({
    required this.host,
    this.timeout = const Duration(seconds: 3),
  });

  final List<Host> host;
  final Duration timeout;
}

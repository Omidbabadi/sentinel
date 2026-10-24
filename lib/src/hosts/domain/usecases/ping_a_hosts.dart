import '../../../../core/common/entities/host.dart';
import '../../../../core/usecase/usecases.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/host_repository.dart';

class PingHost extends UsecaseWithParams<Host, Host> {
  const PingHost(this._repository);
  final HostRepository _repository;

  @override
  ResultFuture<Host> call(Host host) => _repository.pingHost(host: host);
}

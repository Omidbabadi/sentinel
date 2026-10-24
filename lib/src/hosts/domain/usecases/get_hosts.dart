import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/hosts/domain/repositories/host_repository.dart';

class GetHosts extends UsecaseWithOutParams<List<Host>> {
  const GetHosts(this._repository);
  final HostRepository _repository;

  @override
  ResultFuture<List<Host>> call() => _repository.getHosts();
}

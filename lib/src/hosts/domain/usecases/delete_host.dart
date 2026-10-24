import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/hosts/domain/repositories/host_repository.dart';

class DeleteHost extends UsecaseWithParams<void, int> {
  const DeleteHost(this._repository);
  final HostRepository _repository;

  @override
  ResultFuture<void> call(int hostId) => _repository.delete(hostId);
}

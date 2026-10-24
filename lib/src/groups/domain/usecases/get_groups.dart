import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/groups/domain/repositories/group_repository.dart';

class GetGroups extends UsecaseWithOutParams<List<ServerGroup>> {
  const GetGroups(this._repository);

  final GroupRepository _repository;

  @override
  ResultFuture<List<ServerGroup>> call() => _repository.getGroups();
}

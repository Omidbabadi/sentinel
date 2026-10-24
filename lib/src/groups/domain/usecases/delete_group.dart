import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/groups/domain/repositories/group_repository.dart';

class DeleteGroup extends UsecaseWithParams<void, DeleteGroupParams> {
  const DeleteGroup(this._repository);

  final GroupRepository _repository;

  @override
  ResultFuture<void> call(DeleteGroupParams params) => _repository.deleteGroup(
    id: params.id,
    groupName: params.groupName,
  );
}

class DeleteGroupParams {
  const DeleteGroupParams({
    required this.id,
    required this.groupName,
  });

  final int id;
  final String groupName;
}

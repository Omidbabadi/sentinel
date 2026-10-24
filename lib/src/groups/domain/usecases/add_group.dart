import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/groups/domain/repositories/group_repository.dart';

class AddGroup extends UsecaseWithParams<int, AddGroupParams> {
  const AddGroup(this._repository);

  final GroupRepository _repository;

  @override
  ResultFuture<int> call(AddGroupParams params) => _repository.addGroup(
    group: params.group,
    assignedHostIds: params.assignedHostIds,
  );
}

class AddGroupParams {
  const AddGroupParams({
    required this.group,
    this.assignedHostIds = const [],
  });

  final ServerGroup group;
  final List<int> assignedHostIds;
}

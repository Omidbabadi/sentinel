import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/groups/domain/repositories/group_repository.dart';

class UpdateGroup extends UsecaseWithParams<void, UpdateGroupParams> {
  const UpdateGroup(this._repository);

  final GroupRepository _repository;

  @override
  ResultFuture<void> call(UpdateGroupParams params) => _repository.updateGroup(
    group: params.group,
    previousName: params.previousName,
    assignedHostIds: params.assignedHostIds,
  );
}

class UpdateGroupParams {
  const UpdateGroupParams({
    required this.group,
    this.previousName,
    this.assignedHostIds,
  });

  final ServerGroup group;
  final String? previousName;
  final List<int>? assignedHostIds;
}

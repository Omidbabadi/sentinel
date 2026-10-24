import 'package:sentinel/core/usecase/usecases.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/groups/domain/repositories/group_repository.dart';

class AssignHostsToGroup
    extends UsecaseWithParams<void, AssignHostsToGroupParams> {
  const AssignHostsToGroup(this._repository);

  final GroupRepository _repository;

  @override
  ResultFuture<void> call(AssignHostsToGroupParams params) =>
      _repository.assignHostsToGroup(
        groupName: params.groupName,
        hostIds: params.hostIds,
      );
}

class AssignHostsToGroupParams {
  const AssignHostsToGroupParams({
    required this.groupName,
    required this.hostIds,
  });

  final String groupName;
  final List<int> hostIds;
}

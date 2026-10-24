import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/utils/typedefs.dart';

abstract class GroupRepository {
  const GroupRepository();

  ResultFuture<List<ServerGroup>> getGroups();

  ResultFuture<int> addGroup({
    required ServerGroup group,
    List<int> assignedHostIds = const [],
  });

  ResultFuture<void> updateGroup({
    required ServerGroup group,
    String? previousName,
    List<int>? assignedHostIds,
  });

  ResultFuture<void> deleteGroup({
    required int id,
    required String groupName,
  });

  ResultFuture<void> assignHostsToGroup({
    required String groupName,
    required List<int> hostIds,
  });
}

import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/src/groups/domain/usecases/add_group.dart';
import 'package:sentinel/src/groups/domain/usecases/assign_hosts_to_group.dart';
import 'package:sentinel/src/groups/domain/usecases/delete_group.dart';
import 'package:sentinel/src/groups/domain/usecases/get_groups.dart';
import 'package:sentinel/src/groups/domain/usecases/update_group.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';

part 'groups_adapter.g.dart';
part 'groups_state.dart';

@Riverpod(keepAlive: true)
class GroupsAdapter extends _$GroupsAdapter {
  late final GetGroups _getGroups;
  late final AddGroup _addGroup;
  late final UpdateGroup _updateGroup;
  late final DeleteGroup _deleteGroup;
  late final AssignHostsToGroup _assignHostsToGroup;

  @override
  GroupsState build() {
    _getGroups = sl<GetGroups>();
    _addGroup = sl<AddGroup>();
    _updateGroup = sl<UpdateGroup>();
    _deleteGroup = sl<DeleteGroup>();
    _assignHostsToGroup = sl<AssignHostsToGroup>();

    return const GroupsInitial();
  }

  Future<void> getGroupsFromLocalBase() async {
    state = const GroupsLoading();
    final result = await _getGroups.call();
    result.fold(
      (l) => state = GroupsError(l.message),
      (r) => state = GroupsLoaded(r),
    );
  }

  Future<bool> addGroup({
    required ServerGroup group,
    List<int> assignedHostIds = const [],
  }) async {
    state = const GroupsLoading();
    final result = await _addGroup.call(
      AddGroupParams(group: group, assignedHostIds: assignedHostIds),
    );

    var success = false;
    await result.fold(
      (l) async => state = GroupsError(l.message),
      (r) async {
        success = true;
        await getGroupsFromLocalBase();
        if (assignedHostIds.isNotEmpty) {
          await ref
              .read(hostsAdapterProvider.notifier)
              .getHostFromLocalBase(pingAfterLoad: false);
        }
      },
    );
    return success;
  }

  Future<bool> updateGroup({
    required ServerGroup group,
    String? previousName,
    List<int>? assignedHostIds,
  }) async {
    state = const GroupsLoading();
    final result = await _updateGroup.call(
      UpdateGroupParams(
        group: group,
        previousName: previousName,
        assignedHostIds: assignedHostIds,
      ),
    );

    var success = false;
    await result.fold(
      (l) async => state = GroupsError(l.message),
      (r) async {
        success = true;
        await getGroupsFromLocalBase();
        await ref
            .read(hostsAdapterProvider.notifier)
            .getHostFromLocalBase(pingAfterLoad: false);
      },
    );
    return success;
  }

  Future<bool> deleteGroup({
    required int id,
    required String groupName,
  }) async {
    final result = await _deleteGroup.call(
      DeleteGroupParams(id: id, groupName: groupName),
    );

    var success = false;
    await result.fold(
      (l) async => state = GroupsError(l.message),
      (r) async {
        success = true;
        await getGroupsFromLocalBase();
        await ref
            .read(hostsAdapterProvider.notifier)
            .getHostFromLocalBase(pingAfterLoad: false);
      },
    );
    return success;
  }

  Future<bool> assignHostsToGroup({
    required String groupName,
    required List<int> hostIds,
  }) async {
    final result = await _assignHostsToGroup.call(
      AssignHostsToGroupParams(groupName: groupName, hostIds: hostIds),
    );

    var success = false;
    await result.fold(
      (l) async => state = GroupsError(l.message),
      (r) async {
        success = true;
        await getGroupsFromLocalBase();
        await ref
            .read(hostsAdapterProvider.notifier)
            .getHostFromLocalBase(pingAfterLoad: false);
      },
    );
    return success;
  }
}

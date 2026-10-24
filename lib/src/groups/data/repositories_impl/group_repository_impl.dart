import 'package:dartz/dartz.dart';
import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/errors/exceptions.dart';
import 'package:sentinel/core/errors/failures.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/groups/data/datasrc/group_local_datasrc.dart';
import 'package:sentinel/src/groups/data/model/server_group_model.dart';
import 'package:sentinel/src/groups/domain/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  const GroupRepositoryImpl(this._localDatasrc);

  final GroupLocalDatasrc _localDatasrc;

  ServerGroupModel _toModel(ServerGroup group) {
    if (group is ServerGroupModel) return group;
    return ServerGroupModel.fromEntity(group);
  }

  @override
  ResultFuture<List<ServerGroup>> getGroups() async {
    try {
      final groups = await _localDatasrc.getGroups();
      return Right(groups);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  @override
  ResultFuture<int> addGroup({
    required ServerGroup group,
    List<int> assignedHostIds = const [],
  }) async {
    try {
      final id = await _localDatasrc.addGroup(
        group: _toModel(group),
        assignedHostIds: assignedHostIds,
      );
      return Right(id);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  @override
  ResultFuture<void> updateGroup({
    required ServerGroup group,
    String? previousName,
    List<int>? assignedHostIds,
  }) async {
    try {
      await _localDatasrc.updateGroup(
        group: _toModel(group),
        previousName: previousName,
        assignedHostIds: assignedHostIds,
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  @override
  ResultFuture<void> deleteGroup({
    required int id,
    required String groupName,
  }) async {
    try {
      await _localDatasrc.deleteGroup(id: id, groupName: groupName);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }

  @override
  ResultFuture<void> assignHostsToGroup({
    required String groupName,
    required List<int> hostIds,
  }) async {
    try {
      await _localDatasrc.assignHostsToGroup(
        groupName: groupName,
        hostIds: hostIds,
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure.fromException(e));
    }
  }
}

part of 'groups_adapter.dart';

sealed class GroupsState extends Equatable {
  const GroupsState();

  @override
  List<Object?> get props => [];
}

final class GroupsInitial extends GroupsState {
  const GroupsInitial();
}

final class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

final class GroupsLoaded extends GroupsState {
  const GroupsLoaded(this.groups);

  final List<ServerGroup> groups;

  @override
  List<Object?> get props => [groups];
}

final class GroupsError extends GroupsState {
  const GroupsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

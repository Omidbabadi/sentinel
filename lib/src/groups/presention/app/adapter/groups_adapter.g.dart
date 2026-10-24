// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groups_adapter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GroupsAdapter)
final groupsAdapterProvider = GroupsAdapterProvider._();

final class GroupsAdapterProvider
    extends $NotifierProvider<GroupsAdapter, GroupsState> {
  GroupsAdapterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupsAdapterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupsAdapterHash();

  @$internal
  @override
  GroupsAdapter create() => GroupsAdapter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupsState>(value),
    );
  }
}

String _$groupsAdapterHash() => r'a8193bc04127894fb82301a495c2d9174a0516ef';

abstract class _$GroupsAdapter extends $Notifier<GroupsState> {
  GroupsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GroupsState, GroupsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GroupsState, GroupsState>,
              GroupsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

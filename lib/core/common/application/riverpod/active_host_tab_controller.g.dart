// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_host_tab_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveHostTabController)
final activeHostTabControllerProvider = ActiveHostTabControllerProvider._();

final class ActiveHostTabControllerProvider
    extends $NotifierProvider<ActiveHostTabController, ActiveTabsState> {
  ActiveHostTabControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeHostTabControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeHostTabControllerHash();

  @$internal
  @override
  ActiveHostTabController create() => ActiveHostTabController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveTabsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveTabsState>(value),
    );
  }
}

String _$activeHostTabControllerHash() =>
    r'b4c8f3ad66ff52c89547ba0419a1c9eb70b25b1a';

abstract class _$ActiveHostTabController extends $Notifier<ActiveTabsState> {
  ActiveTabsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ActiveTabsState, ActiveTabsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActiveTabsState, ActiveTabsState>,
              ActiveTabsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

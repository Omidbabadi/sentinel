// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hosts_adapter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HostsAdapter)
final hostsAdapterProvider = HostsAdapterProvider._();

final class HostsAdapterProvider
    extends $NotifierProvider<HostsAdapter, HostsState> {
  HostsAdapterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostsAdapterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostsAdapterHash();

  @$internal
  @override
  HostsAdapter create() => HostsAdapter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HostsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HostsState>(value),
    );
  }
}

String _$hostsAdapterHash() => r'f495fc01731d4bc64949d13b089c1df616ef0515';

abstract class _$HostsAdapter extends $Notifier<HostsState> {
  HostsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HostsState, HostsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HostsState, HostsState>,
              HostsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

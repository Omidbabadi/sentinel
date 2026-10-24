// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'internet_connectivity_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InternetConnectivityController)
final internetConnectivityControllerProvider =
    InternetConnectivityControllerProvider._();

final class InternetConnectivityControllerProvider
    extends $StreamNotifierProvider<InternetConnectivityController, bool> {
  InternetConnectivityControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'internetConnectivityControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$internetConnectivityControllerHash();

  @$internal
  @override
  InternetConnectivityController create() => InternetConnectivityController();
}

String _$internetConnectivityControllerHash() =>
    r'1f78005700b44d1d54df60220d655c044752a472';

abstract class _$InternetConnectivityController extends $StreamNotifier<bool> {
  Stream<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

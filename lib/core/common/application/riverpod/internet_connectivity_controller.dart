import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentinel/core/services/injection_container.dart';

import '../../internet_conectivity.dart';

part 'internet_connectivity_controller.g.dart';

@Riverpod(keepAlive: true)
class InternetConnectivityController extends _$InternetConnectivityController {
  @override
  Stream<bool> build() async* {
    final netInfo = sl<NetworkInfo>();

    yield netInfo.isConnected;
    yield* netInfo.onConnectivityChanged;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/services/injection_container.dart';

//void main() async {
// WidgetsFlutterBinding.ensureInitialized();
//await init();
//runApp(ProviderScope(child: const MainApp()));
//}

import 'package:flutter/services.dart';
import 'package:sentinel/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await init();

  runApp(const ProviderScope(child: MainApp()));
}

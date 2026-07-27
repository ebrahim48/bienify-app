import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/dependency_injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bienify is a portrait-first experience; the fixed-height controls in the
  // design have no landscape counterpart.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Services, repositories and use cases must exist before the first route
  // binding runs.
  await DependencyInjection.init();

  runApp(const BienifyApp());
}

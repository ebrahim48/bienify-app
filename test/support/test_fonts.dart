import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the app's real fonts into the test binding.
///
/// Without this, `flutter_test` substitutes a placeholder face whose glyphs
/// are far wider than Satoshi's. Layouts that fit on a real device then
/// overflow in tests, producing failures that say nothing about the code.
/// Call it from `setUpAll` in any test that lays out text.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const satoshi = [
    'assets/fonts/Satoshi-Light.otf',
    'assets/fonts/Satoshi-Regular.otf',
    'assets/fonts/Satoshi-Medium.otf',
    'assets/fonts/Satoshi-Bold.otf',
    'assets/fonts/Satoshi-Black.otf',
  ];

  final loader = FontLoader('Satoshi');
  for (final face in satoshi) {
    loader.addFont(rootBundle.load(face));
  }
  await loader.load();

  // The test binding ships no icon font, so `Icon` would otherwise render as
  // empty boxes and hide real glyph problems.
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

/// Lets pending image decodes finish so golden output shows real photos.
///
/// `Image.asset` decodes off the main isolate, which the fake async clock in
/// `flutter_test` never advances — without this, avatars render as empty
/// circles and a genuine layout problem would be indistinguishable from a
/// timing artefact.
Future<void> settleImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  });
  await tester.pump();
  // Also lets short implicit animations finish — a `Switch` toggled just
  // before capture would otherwise be frozen at its starting position and
  // look like it never moved.
  await tester.pump(const Duration(milliseconds: 300));
}

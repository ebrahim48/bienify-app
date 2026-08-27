import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Proves the app can actually reach every endpoint the backend serves.
///
/// The failure this guards against is silent: a route gets added or renamed on
/// the server, the app keeps calling the old path, and nothing complains until
/// a screen 404s in someone's hands. `test/fixtures/backend-routes.json` is a
/// copy of the backend's own route table — when it is refreshed and a route
/// here has no Dart caller, this test says so by name.
void main() {
  late List<List<String>> routes;
  late String apiSource;
  late String constants;

  setUpAll(() {
    routes =
        (jsonDecode(
                  File('test/fixtures/backend-routes.json').readAsStringSync(),
                )
                as List)
            .map((r) => (r as List).map((e) => e as String).toList())
            .toList();

    apiSource = Directory(
      'lib/core/network/api',
    ).listSync().whereType<File>().map((f) => f.readAsStringSync()).join('\n');

    constants = File(
      'lib/core/constants/api_constants.dart',
    ).readAsStringSync();
  });

  test('the backend serves the number of routes we think it does', () {
    // 161 with the courier thread: `GET`/`POST /deliveries/:id/messages` and
    // its attachment presign join the door photo, chat attachments, the two
    // lapse remedies, the doctor's refund and the lab-order review.
    expect(routes, hasLength(161));
  });

  test('every backend route has a constant holding its exact path', () {
    final missing = <String>[];

    for (final route in routes) {
      final path = route[1];
      // ':id' becomes an interpolated '$id' in the Dart constant.
      final expected = path
          .replaceAll('/api/v1', r'$_v1')
          .replaceAllMapped(RegExp(r':(\w+)'), (m) => '\$${m[1]}');
      if (!constants.contains("'$expected'")) missing.add('${route[0]} $path');
    }

    expect(missing, isEmpty, reason: 'no ApiConstants entry for these routes');
  });

  test('every backend route has a Dart method that calls it', () {
    final uncalled = <String>[];

    for (final route in routes) {
      final path = route[1];
      final expected = path
          .replaceAll('/api/v1', r'$_v1')
          .replaceAllMapped(RegExp(r':(\w+)'), (m) => '\$${m[1]}');

      // Find which constant holds this path, then confirm an API class uses it.
      final decl = RegExp(
        r'static (?:const String|String) (\w+)[^=]*=[^;]*' +
            RegExp.escape("'$expected'"),
      ).firstMatch(constants);

      if (decl == null) {
        uncalled.add('${route[0]} $path (no constant)');
        continue;
      }
      final name = decl.group(1)!;
      if (!RegExp(r'ApiConstants\.' + name + r'\b').hasMatch(apiSource)) {
        uncalled.add('${route[0]} $path (ApiConstants.$name is never called)');
      }
    }

    expect(
      uncalled,
      isEmpty,
      reason: 'these endpoints are unreachable from the app',
    );
  });

  test('no API method points at a path the backend does not serve', () {
    final served = routes.map((r) => r[1]).toSet();
    final stray = <String>[];

    for (final m in RegExp(r"'\$_v1(/[^']*)'").allMatches(constants)) {
      final dartPath = '/api/v1${m.group(1)}';
      final real = dartPath.replaceAllMapped(
        RegExp(r'\$(\w+)'),
        (x) => ':${x[1]}',
      );
      if (!served.contains(real)) stray.add(real);
    }

    expect(
      stray,
      isEmpty,
      reason: 'the app declares paths the server will 404',
    );
  });
}

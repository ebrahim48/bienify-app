import 'package:bienify_app/core/models/country.dart';
import 'package:bienify_app/core/utils/validators.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/entities/age_range.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/entities/gender.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Unit coverage for the pure logic behind the auth forms.
///
/// The screens are thin views over these rules, which is where the risk sits.
void main() {
  setUpAll(() {
    // Validators return translated copy, so GetX has to be initialised
    // before any of them run.
    Get.testMode = true;
  });

  group('Validators.email', () {
    test('accepts a well-formed address', () {
      expect(Validators.email('user@bienify.app'), isNull);
    });

    test('rejects an empty value', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects a missing domain', () {
      expect(Validators.email('user@'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('accepts eight characters or more', () {
      expect(Validators.password('supersecret'), isNull);
    });

    test('rejects anything shorter', () {
      expect(Validators.password('short'), isNotNull);
    });

    test('confirmPassword rejects a mismatch', () {
      expect(
        Validators.confirmPassword('supersecret', 'supersecrer'),
        isNotNull,
      );
    });
  });

  group('Validators.phone', () {
    test('accepts a full South African national number', () {
      expect(Validators.phone('821234567', Countries.southAfrica), isNull);
    });

    test('rejects a number that is far too short', () {
      expect(Validators.phone('82', Countries.southAfrica), isNotNull);
    });

    test('rejects non-digits', () {
      expect(Validators.phone('82abc4567', Countries.southAfrica), isNotNull);
    });
  });

  group('Validators.otp', () {
    test('accepts exactly six digits', () {
      expect(Validators.otp('123456'), isNull);
    });

    test('rejects five digits', () {
      expect(Validators.otp('12345'), isNotNull);
    });
  });

  group('Country', () {
    test('derives a flag from the ISO code', () {
      expect(Countries.southAfrica.flagEmoji, '🇿🇦');
    });

    test('search matches name, ISO code and dial code', () {
      expect(Countries.search('south'), contains(Countries.southAfrica));
      expect(Countries.search('+27'), contains(Countries.southAfrica));
      expect(Countries.search('za'), contains(Countries.southAfrica));
    });
  });

  group('Domain enums round-trip their wire format', () {
    test('Gender', () {
      expect(Gender.fromValue('female'), Gender.female);
      expect(Gender.fromValue('nope'), isNull);
    });

    test('AgeRange', () {
      expect(AgeRange.fromLabel('25-32'), AgeRange.age25to32);
      expect(AgeRange.fromLabel('nope'), isNull);
    });
  });
}

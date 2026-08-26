import 'package:flutter_test/flutter_test.dart';
import 'package:peak_predictor/core/formatters.dart';
import 'package:peak_predictor/core/validators.dart';

void main() {
  group('Validators', () {
    test('rejects a malformed email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('someone@example.com'), isNull);
    });

    test('requires a password with a letter, a number and eight characters', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('alphabetical'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('commuter1'), isNull);
    });

    test('confirms a matching password', () {
      expect(Validators.confirmPassword('commuter1', 'commuter1'), isNull);
      expect(Validators.confirmPassword('commuter2', 'commuter1'), isNotNull);
    });

    test('rejects a journey with identical endpoints', () {
      expect(Validators.distinctStations('kl_sentral', 'kl_sentral'), isNotNull);
      expect(Validators.distinctStations('kl_sentral', 'pasar_seni'), isNull);
      expect(Validators.requiredStation(null, 'starting'), isNotNull);
    });
  });

  group('Formatters', () {
    test('groups thousands', () {
      expect(Formatters.thousands(0), '0');
      expect(Formatters.thousands(999), '999');
      expect(Formatters.thousands(302283), '302,283');
    });

    test('labels hours in twelve hour time', () {
      expect(Formatters.hourLabel(0), '12am');
      expect(Formatters.hourLabel(8), '8am');
      expect(Formatters.hourLabel(12), '12pm');
      expect(Formatters.hourLabel(18), '6pm');
    });

    test('formats an ISO date', () {
      expect(Formatters.isoDate(DateTime(2026, 7, 31)), '2026-07-31');
      expect(Formatters.weekdayShort(DateTime(2026, 7, 31)), 'FRI');
    });
  });
}

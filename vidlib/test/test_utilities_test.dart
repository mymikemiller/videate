import 'package:test/test.dart';
import 'package:vidlib/src/test_utilities.dart';

void main() {
  group('autofix', () {
    // autofix should always be set to [false] in production.
    test('is set to false in production', () {
      expect(TestUtilities.autofix, false);
    });
  });
}

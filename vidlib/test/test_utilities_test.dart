import 'package:test/test.dart';
import 'package:vidlib/src/test_utilities.dart';

void main() {
  group('test_utilities.dart', () {
    // autofix should always be set to [false] in production.
    test('does not set autofix', () {
      expect(TestUtilities.autofix, false);
    });
  });
}

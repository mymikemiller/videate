import 'package:test/test.dart';
import 'serialization_testing.dart';

void main() {
  group('serialiation_testing.dart', () {
    // forceUpdateExpectedJsonFile should always be set to [false] in source
    // control.
    test('does not set forceUpdateExpectedJsonFile', () {
      expect(forceUpdateExpectedJsonFile, false);
    });
  });
}

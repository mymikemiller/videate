import 'package:test/test.dart';
import '../../bin/integrations/internet_computer/internet_computer_feed_manager.dart';

void main() async {
  group('Candid Parser', () {
    setUp(() async {});

    test('throws error when parsing empty string', () async {
      // Trying to access the feed should throw a StateError with a helpful
      // message
      expect(
          () => InternetComputerFeedManager.parseCandid(''), throwsStateError);
    });

    test('parses string', () async {
      expect(InternetComputerFeedManager.parseCandid('"hello";'),
          CandidResult(StringValue('hello'), ''));
    });

    test('parses number', () async {
      expect(InternetComputerFeedManager.parseCandid('123_456.789;'),
          CandidResult(NumberValue(123456.789), ''));
    });

    test('parses record', () async {
      expect(
          InternetComputerFeedManager.parseCandid(
              'record {key1="val1"; key2="val2"; }'),
          CandidResult(
              RecordValue(
                  {'key1': StringValue('val1'), 'key2': StringValue('val2')}),
              ''));
    });

    test('parses empty vector', () async {
      expect(InternetComputerFeedManager.parseCandid('vec {};'),
          CandidResult(VectorValue([]), ''));
    });

    test('parses vector of records', () async {
      expect(
          InternetComputerFeedManager.parseCandid(
              'vec { record {key1="val1"; key2="val2"; }; record {key3="val3"; key4="val4"; }};'),
          CandidResult(
              VectorValue([
                RecordValue(
                    {'key1': StringValue('val1'), 'key2': StringValue('val2')}),
                RecordValue(
                    {'key3': StringValue('val3'), 'key4': StringValue('val4')})
              ]),
              ''));
    });

    test('parses string entry', () async {
      expect(InternetComputerFeedManager.parseCandid('testKey="Test Value";'),
          CandidResult(EntryValue('testKey', StringValue('Test Value')), ''));
    });

    test('parses number entry', () async {
      expect(
          InternetComputerFeedManager.parseCandid('testKey=1_234_567.890_123;'),
          CandidResult(EntryValue('testKey', NumberValue(1234567.890123)), ''));
    });
  });
}

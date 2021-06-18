import 'dart:io';
import '../../bin/integrations/internet_computer/internet_computer_feed_manager.dart';

class MockInternetComputerFeedManager extends InternetComputerFeedManager {
  @override
  String get id => 'internet_computer';

  // Store the candid locally instead of pushing it to the internet computer
  String mostRecentlyWrittenCandid;

  MockInternetComputerFeedManager() : super();

  // Instead of running the dfx command, this process runner caches the candid
  // specified in the arguments so it can be retrieved by calls to populate()
  @override
  ProcessResult Function(String executable, List<String> arguments)
      get processRunner => (String executable, List<String> arguments,
              {String workingDirectory}) {
            final getFeedIndex = arguments.indexOf('getFeed');
            final addFeedIndex = arguments.indexOf('addFeed');

            // For testing, we simply return whatever candid was last written,
            // regardless of the name specified
            if (getFeedIndex > 0) {
              if (mostRecentlyWrittenCandid == null) {
                return ProcessResult(0, 0, '(null)\n', '');
              } else {
                return ProcessResult(0, 0, mostRecentlyWrittenCandid, '');
              }
            } else if (addFeedIndex > 0) {
              final addFeedCandid = arguments[addFeedIndex + 1];
              // The feeds are added in this format:
              // ("feedName", feedCandidString)
              // But we just want feedCandidString, so we extract it
              final regex = RegExp(r'\("\w+", (.*)\)', dotAll: true);
              final match = regex.firstMatch(addFeedCandid);
              mostRecentlyWrittenCandid = match.group(1);
              return ProcessResult(0, 0, '()', '');
            } else {
              throw 'Unrecognized process';
            }
          };
}

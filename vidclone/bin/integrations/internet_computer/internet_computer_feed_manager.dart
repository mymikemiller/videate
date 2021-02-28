import 'package:vidlib/vidlib.dart' hide Platform;
import '../../feed_manager.dart';

// Manages a feed running on dfinity's Internet Computer (https://dfinity.org/)
class InternetComputerFeedManager extends FeedManager {
  String _feedName;

  // The working directory from which to run the dfx commands (i.e. the
  // directory containing a dfx.json file)
  String dfxWorkingDirectory;

  @override
  String get id => 'internet_computer';

  @override
  String get feedName => _feedName;

  @override
  void configure(ClonerTaskArgs feedManagerArgs) {
    _feedName = feedManagerArgs.get('feedName');
    dfxWorkingDirectory = feedManagerArgs.get('dfxWorkingDirectory');
  }

  @override
  Future<bool> populate() async {
    final output = await processRunner(
        'dfx', ['canister', 'call', 'credits', 'getFeed', feedName],
        workingDirectory: dfxWorkingDirectory);

    final stdout = output.stdout;

    if (stdout == '(null)\n)') {
      // No feed found with the given name
      return false;
    }

    print(output);
    return false;
  }

  @override
  Future<void> write() async {}
}

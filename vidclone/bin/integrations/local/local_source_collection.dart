import '../../source_collection.dart';

class LocalSourceCollection extends SourceCollection {
  LocalSourceCollection(String directoryPath) : super(directoryPath);

  @override
  String get platformName => 'Local Folder';

  @override
  String get platformUrl => '';

  @override
  String get identifierMeaning => 'Directory path';
}

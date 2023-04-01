import 'dart:io';

part 'tool.dart';

const excludeTagBegin = 'BEGIN: EXCLUDE_IN_RELEASE';
const excludeTagEnd = 'END: EXCLUDE_IN_RELEASE';

Future<void> main(List<String> args) async {
  const help = '''
A build script that modifies build assets before building the release version of AppFlowy.

args[0]: The directory that contains the AppFlowy git repository. Should be the parent to appflowy_flutter. (absolute path)
''';
  const numArgs = 1;
  assert(args.length == 1,
      'Expected ${numArgs}, got ${args.length}. Read the following for instructions about how to use this script.\n\n$help');
  if (args[0] == '-h' || args[0] == '--help') {
    stdout.write(help);
    stdout.flush();
  }
  final repositoryRoot = Directory(args[0]);
  assert(await repositoryRoot.exists(),
      '$repositoryRoot is an invalid directory. Please try again with a valid directory.\n\n$help');
  await _BuildTool(repositoryRoot: repositoryRoot.path).run();
}

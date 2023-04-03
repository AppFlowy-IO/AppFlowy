import 'dart:io';

part 'tool.dart';

const excludeTagBegin = 'BEGIN: EXCLUDE_IN_RELEASE';
const excludeTagEnd = 'END: EXCLUDE_IN_RELEASE';

Future<void> main(List<String> args) async {
  const help = '''
A build script that modifies build assets before building the release version of AppFlowy.

args[0]: The directory that contains the AppFlowy git repository. Should be the parent to appflowy_flutter. (absolute path)
args[1]: The appflowy version to be built (github ref_name).
''';
  const numArgs = 2;
  assert(args.length == numArgs,
      'Expected ${numArgs}, got ${args.length}. Read the following for instructions about how to use this script.\n\n$help');
  if (args[0] == '-h' || args[0] == '--help') {
    stdout.write(help);
    stdout.flush();
  }
  final repositoryRoot = Directory(args[0]);
  assert(await repositoryRoot.exists(),
      '$repositoryRoot is an invalid directory. Please try again with a valid directory.\n\n$help');
  final appVersion = args[1];
  await _BuildTool(repositoryRoot: repositoryRoot.path, appVersion: appVersion)
      .run();
}

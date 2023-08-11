import 'dart:io';

part 'tool.dart';

const excludeTagBegin = 'BEGIN: EXCLUDE_IN_RELEASE';
const excludeTagEnd = 'END: EXCLUDE_IN_RELEASE';

Future<void> main(List<String> args) async {
  const help = '''
A build script that modifies build assets before building the release version of AppFlowy.

args[0] (required): The subcommand to use (build, include-directives, exclude-directives, run).
  - run: calls exclude-directives, build, include-directives.
  - build: builds the release version of AppFlowy.
  - include-directives: adds the directives from pubspec.yaml.
  - exclude-directives: removes the directives from pubspec.yaml.

args[1] (required): The repository root for appflowy (the directory containing pubspec.yaml).

args[2] (required): version (only relevant for build). The version of the app to build.

''';
  const numArgs = 3;
  assert(args.length == numArgs,
      'Expected ${numArgs}, got ${args.length}. Read the following for instructions about how to use this script.\n\n$help');
  if (args[0] == '-h' || args[0] == '--help') {
    stdout.write(help);
    stdout.flush();
  }

  // parse the vesrion
  final version = args[2];

  // parse the first required argument
  final repositoryRoot = Directory(args[1]);
  assert(await repositoryRoot.exists(),
      '$repositoryRoot is an invalid directory. Please try again with a valid directory.\n\n$help');

  // parse the command
  final command = args[0];
  final tool =
      BuildTool(repositoryRoot: repositoryRoot.path, appVersion: version);

  switch (command) {
    case 'run':
      await tool.run();
      break;
    case 'build':
      await tool.build();
      break;
    case 'include-directives':
      await tool.directives(ModifyMode.include);
      break;
    case 'exclude-directives':
      await tool.directives(ModifyMode.exclude);
      break;
    default:
      throw StateError('Invalid command: $command');
  }
}

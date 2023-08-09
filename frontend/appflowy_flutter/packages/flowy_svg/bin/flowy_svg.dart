import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'options.dart';

const languageKeywords = [
  'abstract',
  'else',
  'import',
  'show',
  'as',
  'enum',
  'static',
  'assert',
  'export',
  'interface',
  'super',
  'async',
  'extends',
  'is',
  'switch',
  'await',
  'extension',
  'late',
  'sync',
  'base',
  'external',
  'library',
  'this',
  'break',
  'factory',
  'mixin',
  'throw',
  'case',
  'false',
  'new',
  'true',
  'catch',
  'final',
  'variable',
  'null',
  'try',
  'class',
  'final',
  'class',
  'on',
  'typedef',
  'const',
  'finally',
  'operator',
  'var',
  'continue',
  'for',
  'part',
  'void',
  'covariant',
  'Function',
  'required',
  'when',
  'default',
  'get',
  'rethrow',
  'while',
  'deferred',
  'hide',
  'return',
  'with',
  'do',
  'if',
  'sealed',
  'yield',
  'dynamic',
  'implements',
  'set',
];

void main(List<String> args) {
  if (_isHelpCommand(args)) {
    _printHelperDisplay();
  } else {
    generateSvgData(_generateOption(args));
  }
}

bool _isHelpCommand(List<String> args) {
  return args.length == 1 && (args[0] == '--help' || args[0] == '-h');
}

void _printHelperDisplay() {
  final parser = _generateArgParser(null);
  log(parser.usage);
}

Options _generateOption(List<String> args) {
  final generateOptions = Options();
  _generateArgParser(generateOptions).parse(args);
  return generateOptions;
}

ArgParser _generateArgParser(Options? generateOptions) {
  final parser = ArgParser()
    ..addOption(
      'source-dir',
      abbr: 'S',
      defaultsTo: '/assets/flowy_icons',
      callback: (String? x) => generateOptions!.sourceDir = x,
      help: 'Folder containing localization files',
    )
    ..addOption(
      'output-dir',
      abbr: 'O',
      defaultsTo: '/lib/generated',
      callback: (String? x) => generateOptions!.outputDir = x,
      help: 'Output folder stores for the generated file',
    )
    ..addOption(
      'name',
      abbr: 'N',
      defaultsTo: 'flowy_svgs.g.dart',
      callback: (String? x) => generateOptions!.outputFile = x,
      help: 'The name of the output file that this tool will generate',
    );

  return parser;
}

Directory source(Options options) => Directory(
      [
        Directory.current.path,
        Directory.fromUri(
          Uri.file(
            options.sourceDir!,
            windows: Platform.isWindows,
          ),
        ).path,
      ].join(),
    );

File output(Options options) => File(
      [
        Directory.current.path,
        Directory.fromUri(
          Uri.file(options.outputDir!, windows: Platform.isWindows),
        ).path,
        Platform.pathSeparator,
        File.fromUri(
          Uri.file(
            options.outputFile!,
            windows: Platform.isWindows,
          ),
        ).path,
      ].join(),
    );

/// generates the svg data
Future<void> generateSvgData(Options options) async {
  // the source directory that this is targeting
  final src = source(options);

  // the output directory that this is targeting
  final out = output(options);

  var files = await dirContents(src);
  files = files.where((f) => f.path.contains('.svg')).toList();

  await generate(files, out, options);
}

/// List the contents of the directory
Future<List<FileSystemEntity>> dirContents(Directory dir) {
  final files = <FileSystemEntity>[];
  final completer = Completer<List<FileSystemEntity>>();

  dir.list(recursive: true).listen(
        files.add,
        onDone: () => completer.complete(files),
      );
  return completer.future;
}

/// Generate the abstract class for the FlowySvg data.
Future<void> generate(
  List<FileSystemEntity> files,
  File output,
  Options options,
) async {
  final generated = File(output.path);

  // create the output file if it doesn't exist
  if (!generated.existsSync()) {
    generated.createSync(recursive: true);
  }

  // content of the generated file
  final builder = StringBuffer()..writeln(prelude);
  files.whereType<File>().forEach(
        (element) => builder.writeln(lineFor(element, options)),
      );
  builder.writeln(postlude);

  generated.writeAsStringSync(builder.toString());
}

String lineFor(File file, Options options) {
  final name = varNameFor(file, options);
  return "  static const $name = FlowySvgData('${pathFor(file)}');";
}

String pathFor(File file) {
  final relative = path.relative(file.path, from: Directory.current.path);
  final uri = Uri.file(relative);
  return uri.toFilePath(windows: false);
}

String varNameFor(File file, Options options) {
  final from = source(options).path;

  final relative = Uri.file(path.relative(file.path, from: from));

  final parts = relative.pathSegments;

  final cleaned = parts.map(clean).toList();

  var simplified = cleaned.reversed
      // join all cleaned path segments with an underscore
      .join('_')
      // there are some cases where the segment contains a dart reserved keyword
      // in this case, the path will be suffixed with an underscore which means
      // there will be a double underscore, so we have to replace the double
      // underscore with one underscore
      .replaceAll(RegExp('_+'), '_');

  // rename icon based on relative path folder name (16x, 24x, etc.)
  for (final key in sizeMap.keys) {
    simplified = simplified.replaceAll(key, sizeMap[key]!);
  }

  return simplified;
}

const sizeMap = {r'$16x': 's', r'$24x': 'm', r'$32x': 'lg', r'$40x': 'xl'};

/// cleans the path segment before rejoining the path into a variable name
String clean(String segment) {
  final cleaned = segment
      // replace all dashes with underscores (dash is invalid in
      // a variable name)
      .replaceAll('-', '_')
      // replace all spaces with an underscore
      .replaceAll(RegExp(r'\s+'), '_')
      // replace all file extensions with an empty string
      .replaceAll(RegExp(r'\.[^.]*$'), '')
      // convert everything to lower case
      .toLowerCase();

  if (languageKeywords.contains(cleaned)) {
    return '${cleaned}_';
  } else if (cleaned.startsWith(RegExp('[0-9]'))) {
    return '\$$cleaned';
  }
  return cleaned;
}

/// The prelude for the generated file
const prelude = '''
// DO NOT EDIT. This code is generated by the flowy_svg script

// import the widget with from this package
import 'package:flowy_svg/flowy_svg.dart';

// export as convenience to the programmer
export 'package:flowy_svg/flowy_svg.dart';

/// A class to easily list all the svgs in the app
class FlowySvgs {''';

/// The postlude for the generated file
const postlude = '''
}
''';

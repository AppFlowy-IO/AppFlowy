/// The options for the command line tool
class Options {
  /// The source directory which the tool will use to generate the output file
  String? sourceDir;

  /// The output directory which the tool will use to output the file(s)
  String? outputDir;

  /// The name of the file that will be generated
  String? outputFile;

  @override
  String toString() {
    return '''
Options:
  sourceDir: $sourceDir
  outputDir: $outputDir
  name: $outputFile
''';
  }
}

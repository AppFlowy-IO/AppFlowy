part of 'build_flowy.dart';

enum _ScanMode {
  ignore,
  target,
}

enum ModifyMode {
  include,
  exclude,
}

class BuildTool {
  const BuildTool({
    required this.repositoryRoot,
    required this.appVersion,
    this.arch,
  });

  final String repositoryRoot;
  final String appVersion;
  final String? arch;

  String get projectRoot =>
      [repositoryRoot, 'appflowy_flutter'].join(Platform.pathSeparator);

  File get pubspec =>
      File([projectRoot, 'pubspec.yaml'].join(Platform.pathSeparator));

  Future<String> get _architecture async =>
      await Process.run('uname', ['-m']).then((value) => value.stdout.trim());

  Future<String> get _commandForOS async {
    // Check the operating system and CPU architecture
    final os = Platform.operatingSystem;
    final arch = this.arch ??
        (Platform.isMacOS ? await _architecture : Platform.localHostname);

    // Determine the appropriate command based on the OS and architecture
    if (os == 'windows') {
      return 'cargo make --env APP_VERSION=$appVersion --profile production-windows-x86 appflowy --verbose';
    }

    if (os == 'linux') {
      return 'cargo make --env APP_VERSION=$appVersion --profile production-linux-x86_64 appflowy';
    }

    if (os == 'macos') {
      if (arch == 'x86_64') {
        return 'cargo make --env APP_VERSION=$appVersion --profile production-mac-x86_64 appflowy';
      }
      if (arch == 'arm64') {
        return 'cargo make --env APP_VERSION=$appVersion --profile production-mac-arm64 appflowy';
      }
      throw 'Unsupported CPU architecture: $arch';
    }

    throw 'Unsupported operating system: $os';
  }

  /// Scans a file for lines between # BEGIN: EXCLUDE_IN_RELEASE and
  /// END: EXCLUDE_IN_RELEASE. Will add a comment to remove those assets
  /// from the build.
  Future<void> process_directives(
    File file, {
    required ModifyMode mode,
  }) async {
    // Read the contents of the file into a list
    var lines = await file.readAsLines();

    // Find the lines between BEGIN: EXCLUDE_IN_RELEASE and END: EXCLUDE_IN_RELEASE
    var scanMode = _ScanMode.ignore;
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.contains(excludeTagBegin)) {
        scanMode = _ScanMode.target;
      } else if (line.contains(excludeTagEnd)) {
        scanMode = _ScanMode.ignore;
      } else if (scanMode == _ScanMode.target) {
        lines[i] = _modify(line, mode: mode);
      }
    }

    // Write the modified contents back to the file
    await file.writeAsString(lines.join('\n'), flush: true);
  }

  String _modify(String line, {required ModifyMode mode}) {
    switch (mode) {
      case ModifyMode.include:
        return line.split('#').where((element) => element != '#').join();
      case ModifyMode.exclude:
        return '#$line';
    }
  }

  Future<void> build() async {
    final cwd = Directory.current;
    Directory.current = repositoryRoot;

    final cmd = await _commandForOS;
    // Run the command using the Process.run() function
    // final build = await Process.run('echo', ['hello'], runInShell: true);
    final build =
        await Process.start(cmd.split(' ')[0], cmd.split(' ').sublist(1));
    await stdout.addStream(build.stdout);
    await stderr.addStream(build.stderr);
    Directory.current = cwd;
  }

  Future<void> directives(ModifyMode mode) async {
    await process_directives(pubspec, mode: mode);
  }

  Future<void> run() async {
    final pubspec = this.pubspec;

    await process_directives(pubspec, mode: ModifyMode.exclude);
    await build();
    await process_directives(pubspec, mode: ModifyMode.include);
  }
}

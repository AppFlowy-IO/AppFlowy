import 'dart:io';

import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TestWorkspace {
  board("board");

  const TestWorkspace(this._name);

  static const String _prefix = "integration_test/util/test_workspaces";

  final String _name;
  String get zip => "${Directory.current.path}/$_prefix/$_name.zip";
  String get _out => "${Directory.current.path}/$_prefix/.ephemeral/";
  String get directory => "$_out/$name";
}

class TestWorkspaceService {
  const TestWorkspaceService(this.workspace);

  final TestWorkspace workspace;

  /// Instructs the application to read workspace data from the workspace found under this [TestWorkspace]'s path.
  Future<void> setUpAll() async {
    SharedPreferences.setMockInitialValues(
      {kSettingsLocationDefaultLocation: TestWorkspace.board.directory},
    );
  }

  /// Workspaces that are checked into source are compressed. [TestWorkspaceService.setUp()] decompresses the file into an ephemeral directory that will be ignored by source control.
  Future<void> setUp() async {
    final inputStream = InputFileStream(workspace.zip);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    extractArchiveToDisk(archive, workspace.directory);
  }
}

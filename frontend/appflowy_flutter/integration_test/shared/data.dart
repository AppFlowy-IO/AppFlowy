import 'dart:io';

import 'package:appflowy/core/config/kv_keys.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TestWorkspace {
  board("board"),
  emptyDocument("empty_document"),
  aiWorkSpace("ai_workspace"),
  coverImage("cover_image");

  const TestWorkspace(this._name);

  final String _name;

  Future<File> get zip async {
    final Directory parent = await TestWorkspace._parent;
    final File out = File(p.join(parent.path, '$_name.zip'));
    if (await out.exists()) return out;
    await out.create();
    final ByteData data = await rootBundle.load(_asset);
    await out.writeAsBytes(data.buffer.asUint8List());
    return out;
  }

  Future<Directory> get root async {
    final Directory parent = await TestWorkspace._parent;
    return Directory(p.join(parent.path, _name));
  }

  static Future<Directory> get _parent async {
    final Directory root = await getTemporaryDirectory();
    if (await root.exists()) return root;
    await root.create();
    return root;
  }

  String get _asset => 'assets/test/workspaces/$_name.zip';
}

class TestWorkspaceService {
  const TestWorkspaceService(this.workspace);

  final TestWorkspace workspace;

  /// Instructs the application to read workspace data from the workspace found under this [TestWorkspace]'s path.
  Future<void> setUpAll() async {
    final root = await workspace.root;
    final path = root.path;
    SharedPreferences.setMockInitialValues(
      {
        KVKeys.pathLocation: path,
      },
    );
  }

  /// Workspaces that are checked into source are compressed. [TestWorkspaceService.setUp()] decompresses the file into an ephemeral directory that will be ignored by source control.
  Future<void> setUp() async {
    final inputStream =
        InputFileStream(await workspace.zip.then((value) => value.path));
    final archive = ZipDecoder().decodeBuffer(inputStream);
    extractArchiveToDisk(
      archive,
      await TestWorkspace._parent.then((value) => value.path),
    );
  }
}

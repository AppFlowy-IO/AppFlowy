import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/migration/editor_migration.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('editor migration, from v0.1.x to 0.2', () {
    test('migrate readme', () async {
      final readme = await rootBundle.loadString('assets/template/readme.json');
      final oldDocument = DocumentV0.fromJson(json.decode(readme));
      final document = EditorMigration.migrateDocument(readme);
      expect(document.root.type, 'page');
      expect(oldDocument.root.children.length, document.root.children.length);
    });
  });
}

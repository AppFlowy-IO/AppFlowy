import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_file.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../util.dart';

void main() {
  setUpAll(() async {
    await AppFlowyUnitTest.ensureInitialized();
  });

  group('drop images and files in EditorState', () {
    test('dropImages should insert image node on empty path', () async {
      final editorState = EditorState(
        document: Document.blank(withInitialText: true),
      );
      final dropPath = <int>[1];

      const imagePath = 'assets/test/images/sample.jpeg';
      final imageFile = XFile(imagePath);
      await editorState.dropImages(dropPath, [imageFile], 'documentId', true);

      final node = editorState.getNodeAtPath(dropPath);
      expect(node, isNotNull);
      expect(node!.type, CustomImageBlockKeys.type);
    });

    test('dropFiles should insert file node on empty path', () async {
      final editorState = EditorState(
        document: Document.blank(withInitialText: true),
      );
      final dropPath = <int>[1];

      const filePath = 'assets/test/images/sample.jpeg';
      final file = XFile(filePath);
      await editorState.dropFiles(dropPath, [file], 'documentId', true);

      final node = editorState.getNodeAtPath(dropPath);
      expect(node, isNotNull);
      expect(node!.type, FileBlockKeys.type);
    });
  });
}

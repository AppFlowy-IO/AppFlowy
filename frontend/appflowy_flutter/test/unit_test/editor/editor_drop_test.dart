import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_file.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_image.dart';
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
    test('dropImages on same path as paragraph node ', () async {
      final editorState = EditorState(
        document: Document.blank(withInitialText: true),
      );

      expect(editorState.getNodeAtPath([0])!.type, ParagraphBlockKeys.type);

      const dropPath = <int>[0];

      const imagePath = 'assets/test/images/sample.jpeg';
      final imageFile = XFile(imagePath);
      await editorState.dropImages(dropPath, [imageFile], 'documentId', true);

      final node = editorState.getNodeAtPath(dropPath);
      expect(node, isNotNull);
      expect(node!.type, CustomImageBlockKeys.type);
      expect(editorState.getNodeAtPath([1])!.type, ParagraphBlockKeys.type);
    });

    test('dropImages should insert image node on empty path', () async {
      final editorState = EditorState(
        document: Document.blank(withInitialText: true),
      );

      expect(editorState.getNodeAtPath([0])!.type, ParagraphBlockKeys.type);

      const dropPath = <int>[1];

      const imagePath = 'assets/test/images/sample.jpeg';
      final imageFile = XFile(imagePath);
      await editorState.dropImages(dropPath, [imageFile], 'documentId', true);

      final node = editorState.getNodeAtPath(dropPath);
      expect(node, isNotNull);
      expect(node!.type, CustomImageBlockKeys.type);
      expect(editorState.getNodeAtPath([0])!.type, ParagraphBlockKeys.type);
      expect(editorState.getNodeAtPath([2]), null);
    });

    test('dropFiles on same path as paragraph node ', () async {
      final editorState = EditorState(
        document: Document.blank(withInitialText: true),
      );

      expect(editorState.getNodeAtPath([0])!.type, ParagraphBlockKeys.type);

      const dropPath = <int>[0];

      const filePath = 'assets/test/images/sample.jpeg';
      final file = XFile(filePath);
      await editorState.dropFiles(dropPath, [file], 'documentId', true);

      final node = editorState.getNodeAtPath(dropPath);
      expect(node, isNotNull);
      expect(node!.type, FileBlockKeys.type);
      expect(editorState.getNodeAtPath([1])!.type, ParagraphBlockKeys.type);
    });

    test('dropFiles should insert file node on empty path', () async {
      final editorState = EditorState(
        document: Document.blank(withInitialText: true),
      );
      const dropPath = <int>[1];

      const filePath = 'assets/test/images/sample.jpeg';
      final file = XFile(filePath);
      await editorState.dropFiles(dropPath, [file], 'documentId', true);

      final node = editorState.getNodeAtPath(dropPath);
      expect(node, isNotNull);
      expect(node!.type, FileBlockKeys.type);
      expect(editorState.getNodeAtPath([0])!.type, ParagraphBlockKeys.type);
      expect(editorState.getNodeAtPath([2]), null);
    });
  });
}

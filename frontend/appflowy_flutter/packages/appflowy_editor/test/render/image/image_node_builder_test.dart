import 'package:appflowy_editor/src/service/editor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('image_node_builder.dart', () {
    testWidgets('render image node', (tester) async {
      mockNetworkImagesFor(() async {
        const text = 'Welcome to Appflowy 😁';
        const src =
            'https://images.unsplash.com/photo-1471897488648-5eae4ac6686b?ixlib=rb-1.2.1&dl=sarah-dorweiler-QeVmJxZOv3k-unsplash.jpg&w=640&q=80&fm=jpg&crop=entropy&cs=tinysrgb';
        final editor = tester.editor
          ..insertTextNode(text)
          ..insertImageNode(src)
          ..insertTextNode(text);
        await editor.startTesting();
        await tester.pumpAndSettle();

        expect(editor.documentLength, 3);
        expect(find.byType(Image), findsOneWidget);
      });
    });

    testWidgets('render image align', (tester) async {
      mockNetworkImagesFor(() async {
        const text = 'Welcome to Appflowy 😁';
        const src =
            'https://images.unsplash.com/photo-1471897488648-5eae4ac6686b?ixlib=rb-1.2.1&dl=sarah-dorweiler-QeVmJxZOv3k-unsplash.jpg&w=640&q=80&fm=jpg&crop=entropy&cs=tinysrgb';
        final editor = tester.editor
          ..insertTextNode(text)
          ..insertImageNode(src, align: 'left', width: 100)
          ..insertImageNode(src, align: 'center', width: 100)
          ..insertImageNode(src, align: 'right', width: 100)
          ..insertTextNode(text);
        await editor.startTesting();
        await tester.pumpAndSettle();

        expect(editor.documentLength, 5);
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsNWidgets(3));

        final editorFinder = find.byType(AppFlowyEditor);
        final editorRect = tester.getRect(editorFinder);

        final leftImageRect = tester.getRect(imageFinder.at(0));
        expect(
            leftImageRect.left, editor.editorState.editorStyle.padding!.left);
        final rightImageRect = tester.getRect(imageFinder.at(2));
        expect(rightImageRect.right,
            editorRect.right - editor.editorState.editorStyle.padding!.right);
        final centerImageRect = tester.getRect(imageFinder.at(1));
        expect(centerImageRect.left,
            (leftImageRect.left + rightImageRect.left) / 2.0);
        expect(leftImageRect.size, centerImageRect.size);
        expect(rightImageRect.size, centerImageRect.size);

        final leftImageNode = editor.document.nodeAtPath([1]);

        expect(editor.runAction(1, leftImageNode!), true); // align center
        await tester.pump();
        expect(
          tester.getRect(imageFinder.at(0)).left,
          centerImageRect.left,
        );

        expect(editor.runAction(2, leftImageNode), true); // align right
        await tester.pump();
        expect(
          tester.getRect(imageFinder.at(0)).right,
          rightImageRect.right,
        );
      });
    });

    testWidgets('render image copy', (tester) async {
      mockNetworkImagesFor(() async {
        const text = 'Welcome to Appflowy 😁';
        const src =
            'https://images.unsplash.com/photo-1471897488648-5eae4ac6686b?ixlib=rb-1.2.1&dl=sarah-dorweiler-QeVmJxZOv3k-unsplash.jpg&w=640&q=80&fm=jpg&crop=entropy&cs=tinysrgb';
        final editor = tester.editor
          ..insertTextNode(text)
          ..insertImageNode(src)
          ..insertTextNode(text);
        await editor.startTesting();

        expect(editor.documentLength, 3);
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);

        final imageNode = editor.document.nodeAtPath([1]);

        expect(editor.runAction(3, imageNode!), true); // copy
        await tester.pump();
      });
    });

    testWidgets('render image delete', (tester) async {
      mockNetworkImagesFor(() async {
        const text = 'Welcome to Appflowy 😁';
        const src =
            'https://images.unsplash.com/photo-1471897488648-5eae4ac6686b?ixlib=rb-1.2.1&dl=sarah-dorweiler-QeVmJxZOv3k-unsplash.jpg&w=640&q=80&fm=jpg&crop=entropy&cs=tinysrgb';
        final editor = tester.editor
          ..insertTextNode(text)
          ..insertImageNode(src)
          ..insertImageNode(src)
          ..insertTextNode(text);
        await editor.startTesting();

        expect(editor.documentLength, 4);
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsNWidgets(2));

        final imageNode = editor.document.nodeAtPath([1]);
        expect(editor.runAction(4, imageNode!), true); // delete

        await tester.pump(const Duration(milliseconds: 100));
        expect(editor.documentLength, 3);
        expect(find.byType(Image), findsNWidgets(1));
      });
    });
  });
}

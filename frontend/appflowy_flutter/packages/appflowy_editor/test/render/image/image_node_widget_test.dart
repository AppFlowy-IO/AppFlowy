import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/image/image_node_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('image_node_widget.dart', () {
    testWidgets('build the image node widget', (tester) async {
      mockNetworkImagesFor(() async {
        const src =
            'https://images.unsplash.com/photo-1471897488648-5eae4ac6686b?ixlib=rb-1.2.1&dl=sarah-dorweiler-QeVmJxZOv3k-unsplash.jpg&w=640&q=80&fm=jpg&crop=entropy&cs=tinysrgb';

        final widget = ImageNodeWidget(
          src: src,
          width: 100,
          node: Node(
            type: 'image',
            children: LinkedList(),
            attributes: {
              'image_src': src,
              'align': 'center',
            },
          ),
          alignment: Alignment.center,
          onResize: (width) {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: widget,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final imageNodeFinder = find.byType(ImageNodeWidget);
        expect(imageNodeFinder, findsOneWidget);

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);

        final imageNodeRect = tester.getRect(imageNodeFinder);
        final imageRect = tester.getRect(imageFinder);

        expect(imageRect.width, 100);
        expect((imageNodeRect.left - imageRect.left).abs(),
            (imageNodeRect.right - imageRect.right).abs());
      });
    });
  });
}

import 'package:appflowy_editor/src/render/image/image_node_widget.dart';
import 'package:flutter/gestures.dart';
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
        var onCopyHit = false;
        var onDeleteHit = false;
        var onAlignHit = false;
        const src =
            'https://images.unsplash.com/photo-1471897488648-5eae4ac6686b?ixlib=rb-1.2.1&dl=sarah-dorweiler-QeVmJxZOv3k-unsplash.jpg&w=640&q=80&fm=jpg&crop=entropy&cs=tinysrgb';

        final widget = ImageNodeWidget(
          src: src,
          alignment: Alignment.center,
          onCopy: () {
            onCopyHit = true;
          },
          onDelete: () {
            onDeleteHit = true;
          },
          onAlign: (alignment) {
            onAlignHit = true;
          },
          onResize: (width) {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: widget,
            ),
          ),
        );
        expect(find.byType(ImageNodeWidget), findsOneWidget);

        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);

        expect(find.byType(ImageToolbar), findsNothing);

        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.byType(ImageNodeWidget)));
        await tester.pump();

        expect(find.byType(ImageToolbar), findsOneWidget);

        final iconFinder = find.byType(IconButton);
        expect(iconFinder, findsNWidgets(5));

        await tester.tap(iconFinder.at(0));
        expect(onAlignHit, true);
        onAlignHit = false;

        await tester.tap(iconFinder.at(1));
        expect(onAlignHit, true);
        onAlignHit = false;

        await tester.tap(iconFinder.at(2));
        expect(onAlignHit, true);
        onAlignHit = false;

        await tester.tap(iconFinder.at(3));
        expect(onCopyHit, true);

        await tester.tap(iconFinder.at(4));
        expect(onDeleteHit, true);
      });
    });
  });
}

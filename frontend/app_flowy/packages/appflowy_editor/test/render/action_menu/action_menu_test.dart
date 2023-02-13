import 'package:appflowy_editor/src/render/action_menu/action_menu.dart';
import 'package:appflowy_editor/src/render/action_menu/action_menu_item.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('action_menu.dart', () {
    testWidgets('hover and tap action', (tester) async {
      var actionHit = false;

      final widget = ActionMenuOverlay(
        items: [
          ActionMenuItem.icon(
            iconData: Icons.download,
            onPressed: () => actionHit = true,
          )
        ],
        child: const SizedBox(
          height: 100,
          width: 100,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ChangeNotifierProvider(
              create: (context) => ActionMenuState([]),
              child: widget,
            ),
          ),
        ),
      );
      expect(find.byType(ActionMenuWidget), findsNothing);

      final actionMenuOverlay = find.byType(ActionMenuOverlay);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(actionMenuOverlay));
      await tester.pumpAndSettle();

      final actionMenu = find.byType(ActionMenuWidget);
      expect(actionMenu, findsOneWidget);

      final action = find.descendant(
        of: actionMenu,
        matching: find.byType(ActionMenuItemWidget),
      );
      expect(action, findsOneWidget);

      await tester.tap(action);
      expect(actionHit, true);
    });

    testWidgets('stacked action menu overlays', (tester) async {
      final childWidget = ChangeNotifierProvider(
        create: (context) => ActionMenuState([0, 0]),
        child: ActionMenuOverlay(
          items: [
            ActionMenuItem(
              iconBuilder: ({color, size}) => const Text("child"),
              onPressed: null,
            )
          ],
          child: const SizedBox(
            height: 100,
            width: 100,
          ),
        ),
      );

      final parentWidget = ChangeNotifierProvider(
        create: (context) => ActionMenuState([0]),
        child: ActionMenuOverlay(
          items: [
            ActionMenuItem(
              iconBuilder: ({color, size}) => const Text("parent"),
              onPressed: null,
            )
          ],
          child: childWidget,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(child: parentWidget),
          ),
        ),
      );
      expect(find.byType(ActionMenuWidget), findsNothing);

      final overlays = find.byType(ActionMenuOverlay);
      expect(
        tester.getCenter(overlays.at(0)),
        tester.getCenter(overlays.at(1)),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(overlays.at(0)));
      await tester.pumpAndSettle();

      final actionMenu = find.byType(ActionMenuWidget);
      expect(actionMenu, findsOneWidget);

      expect(find.text("child"), findsOneWidget);
      expect(find.text("parent"), findsNothing);
    });

    testWidgets('customActionMenuBuilder', (tester) async {
      final widget = ActionMenuOverlay(
        items: [
          ActionMenuItem.icon(
            iconData: Icons.download,
            onPressed: null,
          )
        ],
        customActionMenuBuilder: (context, items) {
          return const Positioned.fill(
            child: Center(
              child: Text("custom"),
            ),
          );
        },
        child: const SizedBox(
          height: 100,
          width: 100,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ChangeNotifierProvider(
              create: (context) => ActionMenuState([]),
              child: widget,
            ),
          ),
        ),
      );
      expect(find.text("custom"), findsNothing);

      final actionMenuOverlay = find.byType(ActionMenuOverlay);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(actionMenuOverlay));
      await tester.pumpAndSettle();

      expect(find.text("custom"), findsOneWidget);
    });
  });
}

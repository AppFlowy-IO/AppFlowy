import 'dart:ui';

import 'package:appflowy/workspace/presentation/home/secondary_view_resizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('secondary_view_resizer.dart', () {
    testWidgets('cancels its delayed hover update when disposed',
        (tester) async {
      final widthNotifier = ValueNotifier<double>(500);
      addTearDown(widthNotifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SecondaryViewResizer(
            notifier: widthNotifier,
            child: const SizedBox.expand(),
          ),
        ),
      );

      final mouseRegion = find.descendant(
        of: find.byType(SecondaryViewResizer),
        matching: find.byType(MouseRegion),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(mouseRegion));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      await mouse.removePointer();
    });

    testWidgets('resizes within bounds and clears state when canceled',
        (tester) async {
      final widthNotifier = ValueNotifier<double>(500);
      addTearDown(widthNotifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SecondaryViewResizer(
            notifier: widthNotifier,
            child: const SizedBox.expand(),
          ),
        ),
      );

      final resizer = find.byType(SecondaryViewResizer);
      final indicator = find.descendant(
        of: resizer,
        matching: find.byType(TweenAnimationBuilder<Color?>),
      );
      final mouseRegion = find.descendant(
        of: resizer,
        matching: find.byType(MouseRegion),
      );
      final primaryColor = Theme.of(
        tester.element(resizer),
      ).colorScheme.primary;
      final screenWidth = MediaQuery.sizeOf(tester.element(resizer)).width;
      final dragStart = tester.getCenter(mouseRegion);

      final gesture = await tester.startGesture(
        dragStart,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();

      final resizedWidth = screenWidth - dragStart.dx - 20;
      expect(widthNotifier.value, resizedWidth);
      expect(
        tester.widget<TweenAnimationBuilder<Color?>>(indicator).tween.end,
        primaryColor,
      );

      await gesture.moveTo(const Offset(400, 300));
      await tester.pump();

      expect(widthNotifier.value, resizedWidth);

      await gesture.cancel();
      await tester.pump();

      expect(
        tester.widget<TweenAnimationBuilder<Color?>>(indicator).tween.end,
        Colors.transparent,
      );
    });
  });
}

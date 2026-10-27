import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final connectFocus in [false, true]) {
    testWidgets('Escape closes the popup; owner focus is opt-in: $connectFocus',
        (tester) async {
      final controller = PopoverController();
      final ownerNode = FocusNode();
      final ownerScope = FocusScopeNode();
      var ownerTabCount = 0;
      Widget anchor = Popover(
        controller: controller,
        popupBuilder: (_) => const SizedBox(
          width: 160,
          height: 80,
          child: Text('Property editor'),
        ),
        child: const SizedBox(width: 100, height: 40),
      );
      if (connectFocus) {
        anchor = PopoverFocusScope(parentNode: ownerNode, child: anchor);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusScope(
              node: ownerScope,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.tab) {
                  ownerTabCount++;
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Focus(focusNode: ownerNode, child: anchor),
            ),
          ),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();
      expect(find.text('Property editor'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Property editor'), findsNothing);

      controller.show();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(ownerTabCount, connectFocus ? 1 : 0);
      controller.close();
      await tester.pumpWidget(const SizedBox.shrink());
      ownerNode.dispose();
      ownerScope.dispose();
    });
  }
}

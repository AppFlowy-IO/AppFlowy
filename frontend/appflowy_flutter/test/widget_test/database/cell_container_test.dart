import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

// Mock dependencies
class MockEditableCellWidget extends Mock implements EditableCellWidget {
  @override
  final CellContainerNotifier cellContainerNotifier = CellContainerNotifier();

  @override
  final SingleListenerChangeNotifier requestFocus = SingleListenerChangeNotifier();
}

void main() {
  group('CellContainer Widget Tests', () {
    late MockEditableCellWidget mockChild;

    setUp(() {
      mockChild = MockEditableCellWidget();
    });

    testWidgets('CellContainer creates Focus widget and responds to single tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CellContainer(
              child: mockChild,
              width: 100,
              isPrimary: false,
            ),
          ),
        ),
      );

      final containerFinder = find.byType(CellContainer);
      expect(containerFinder, findsOneWidget);

      final focusFinder = find.descendant(
        of: containerFinder,
        matching: find.byType(Focus),
      );
      expect(focusFinder, findsOneWidget);

      // Verify that tap requests focus
      final focusWidget = tester.widget<Focus>(focusFinder);
      expect(focusWidget.focusNode?.hasFocus, isFalse);

      await tester.tap(containerFinder);
      await tester.pumpAndSettle();

      // Child should not be focused immediately on single tap (only the container node gets focus first)
      expect(mockChild.cellContainerNotifier.isFocus, isFalse);
    });

    testWidgets('CellContainer passes double tap to child requestFocus', (WidgetTester tester) async {
      int requestFocusCalls = 0;
      mockChild.requestFocus.addListener(() {
        requestFocusCalls++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CellContainer(
              child: mockChild,
              width: 100,
              isPrimary: false,
            ),
          ),
        ),
      );

      final containerFinder = find.byType(CellContainer);

      // Perform a double tap
      await tester.tap(containerFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(containerFinder);
      await tester.pumpAndSettle();

      // Double tap should trigger child's requestFocus
      expect(requestFocusCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('CellContainer passes enter key to child requestFocus', (WidgetTester tester) async {
      int requestFocusCalls = 0;
      mockChild.requestFocus.addListener(() {
        requestFocusCalls++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CellContainer(
              child: mockChild,
              width: 100,
              isPrimary: false,
            ),
          ),
        ),
      );

      final containerFinder = find.byType(CellContainer);

      await tester.tap(containerFinder);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(requestFocusCalls, greaterThanOrEqualTo(1));
    });
  });
}

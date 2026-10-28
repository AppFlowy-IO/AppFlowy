import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_material_app.dart';

class _ConfirmPopupMock extends Mock {
  void confirm();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableLevels = [];
    await EasyLocalization.ensureInitialized();
  });

  Widget buildDialog(
    VoidCallback onConfirm, {
    bool closeOnAction = true,
    bool enableKeyboardListener = true,
  }) {
    return Builder(
      builder: (context) {
        return TextButton(
          child: const Text(""),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) {
                return AppFlowyTheme(
                  data: AppFlowyDefaultTheme().light(),
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ConfirmPopup(
                      description: "desc",
                      title: "title",
                      onConfirm: (_) => onConfirm(),
                      closeOnAction: closeOnAction,
                      enableKeyboardListener: enableKeyboardListener,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  testWidgets('confirm dialog shortcut events', (tester) async {
    final callback = _ConfirmPopupMock();

    // escape
    await tester.pumpWidget(
      WidgetTestApp(
        child: buildDialog(callback.confirm),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmPopup), findsOneWidget);

    expect(
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape),
      isTrue,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    verifyNever(() => callback.confirm());

    verifyNever(() => callback.confirm());
    expect(find.byType(ConfirmPopup), findsNothing);

    // enter
    await tester.pumpWidget(
      WidgetTestApp(
        child: buildDialog(callback.confirm),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmPopup), findsOneWidget);

    expect(
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter),
      isTrue,
    );
    verifyNever(() => callback.confirm());
    expect(
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter),
      isTrue,
    );
    verifyNever(() => callback.confirm());

    expect(
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter),
      isTrue,
    );
    await tester.pumpAndSettle();
    verify(() => callback.confirm()).called(1);

    verifyNever(() => callback.confirm());
    expect(find.byType(ConfirmPopup), findsNothing);
  });

  testWidgets('confirm without closing consumes repeated Enter events',
      (tester) async {
    final callback = _ConfirmPopupMock();
    await tester.pumpWidget(
      WidgetTestApp(
        child: buildDialog(callback.confirm, closeOnAction: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.enter), isTrue);
    expect(await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter), isTrue);
    verifyNever(() => callback.confirm());
    expect(await tester.sendKeyUpEvent(LogicalKeyboardKey.enter), isTrue);
    await tester.pumpAndSettle();

    verify(() => callback.confirm()).called(1);
    expect(find.byType(ConfirmPopup), findsOneWidget);

    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA), isFalse);
    expect(await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA), isFalse);
    verifyNever(() => callback.confirm());
  });

  testWidgets('disabled keyboard listener ignores Enter', (tester) async {
    final callback = _ConfirmPopupMock();
    await tester.pumpWidget(
      WidgetTestApp(
        child: buildDialog(callback.confirm, enableKeyboardListener: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.enter), isFalse);
    expect(await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter), isFalse);
    expect(await tester.sendKeyUpEvent(LogicalKeyboardKey.enter), isFalse);
    await tester.pumpAndSettle();

    verifyNever(() => callback.confirm());
    expect(find.byType(ConfirmPopup), findsOneWidget);
  });
}

import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../integration_test/shared/util.dart';
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

  Widget buildDialog(VoidCallback onConfirm) {
    return Builder(
      builder: (context) {
        return TextButton(
          child: const Text(""),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ConfirmPopup(
                    description: "desc",
                    title: "title",
                    onConfirm: onConfirm,
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

    await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
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

    await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
    verify(() => callback.confirm()).called(1);

    verifyNever(() => callback.confirm());
    expect(find.byType(ConfirmPopup), findsNothing);
  });
}

import 'package:appflowy/user/presentation/screens/workspace_start_screen/mobile_workspace_start_screen.dart';
import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_app.dart';

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
    await EasyLocalization.ensureInitialized();
  });

  group('MobileWorkspaceStartScreen', () {
    testWidgets('disables get started when workspaces are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        WidgetTestApp(
          child: MobileWorkspaceStartScreen(
            workspaceState: WorkspaceState(
              isLoading: false,
              workspaces: const [],
              successOrFailure: FlowyResult.success(null),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}

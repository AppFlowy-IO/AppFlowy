import 'dart:ui';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Editor AppLifeCycle tests', () {
    testWidgets(
      'Selection is added back after pausing AppFlowy',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapAnonymousSignInButton();

        final selection = Selection.single(path: [4], startOffset: 0);
        await tester.editor.updateSelection(selection);

        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        expect(tester.editor.getCurrentEditorState().selection, null);

        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        expect(tester.editor.getCurrentEditorState().selection, selection);
      },
    );
  });
}

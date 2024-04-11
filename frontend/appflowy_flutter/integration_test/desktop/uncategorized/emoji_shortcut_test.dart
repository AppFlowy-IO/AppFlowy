import 'dart:io';

import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // May be better to move this to an existing test but unsure what it fits with
  group('Keyboard shortcuts related to emojis', () {
    testWidgets('cmd/ctrl+alt+e shortcut opens the emoji picker',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      final Finder editor = find.byType(AppFlowyEditor);
      await tester.tap(editor);
      await tester.pumpAndSettle();

      expect(find.byType(EmojiSelectionMenu), findsNothing);

      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.keyE,
        ],
        tester: tester,
      );

      expect(find.byType(EmojiSelectionMenu), findsOneWidget);
    });
  });
}

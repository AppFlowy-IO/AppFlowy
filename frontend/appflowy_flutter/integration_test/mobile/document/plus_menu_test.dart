import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document plus menu:', () {
    testWidgets('add the toggle heading blocks via plus menu', (tester) async {
      await tester.launchInAnonymousMode();
      await tester.createNewDocumentOnMobile('toggle heading blocks');

      final editorState = tester.editor.getCurrentEditorState();
      // focus on the editor
      unawaited(
        editorState.updateSelectionWithReason(
          Selection.collapsed(Position(path: [0])),
          reason: SelectionUpdateReason.uiEvent,
        ),
      );
      await tester.pumpAndSettle();

      // open the plus menu and select the toggle heading block
      await tester.openPlusMenuAndClickButton(
        LocaleKeys.document_slashMenu_name_toggleHeading1.tr(),
      );

      // check the block is inserted
      final block1 = editorState.getNodeAtPath([0])!;
      expect(block1.type, equals(ToggleListBlockKeys.type));
      expect(block1.attributes[ToggleListBlockKeys.level], equals(1));

      // click the expand button won't cancel the selection
      await tester.tapButton(find.byIcon(Icons.arrow_right));
      expect(
        editorState.selection,
        equals(Selection.collapsed(Position(path: [0]))),
      );

      // focus on the next line
      unawaited(
        editorState.updateSelectionWithReason(
          Selection.collapsed(Position(path: [1])),
          reason: SelectionUpdateReason.uiEvent,
        ),
      );
      await tester.pumpAndSettle();

      // open the plus menu and select the toggle heading block
      await tester.openPlusMenuAndClickButton(
        LocaleKeys.document_slashMenu_name_toggleHeading2.tr(),
      );

      // check the block is inserted
      final block2 = editorState.getNodeAtPath([1])!;
      expect(block2.type, equals(ToggleListBlockKeys.type));
      expect(block2.attributes[ToggleListBlockKeys.level], equals(2));

      // focus on the next line
      await tester.pumpAndSettle();

      // open the plus menu and select the toggle heading block
      await tester.openPlusMenuAndClickButton(
        LocaleKeys.document_slashMenu_name_toggleHeading3.tr(),
      );

      // check the block is inserted
      final block3 = editorState.getNodeAtPath([2])!;
      expect(block3.type, equals(ToggleListBlockKeys.type));
      expect(block3.attributes[ToggleListBlockKeys.level], equals(3));

      // wait a few milliseconds to ensure the selection is updated
      await Future.delayed(const Duration(milliseconds: 100));
      // check the selection is collapsed
      expect(
        editorState.selection,
        equals(Selection.collapsed(Position(path: [2]))),
      );
    });
  });
}

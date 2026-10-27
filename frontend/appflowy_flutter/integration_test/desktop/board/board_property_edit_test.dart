import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/domain/cell_service.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/domain/field_settings_service.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_shortcut_container.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_focus_scope.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/card/container/accessory.dart';
import 'package:appflowy/plugins/database/widgets/cell/board_card_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/checkbox_card_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/text_card_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/timestamp_card_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/date_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/relation_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/row_detail.dart';
import 'package:appflowy/plugins/database/widgets/row/row_property.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('edit board card properties', () {
    testWidgets('expand button only appears when hovering an editing card',
        (tester) async {
      final (RowCard card, FieldPB _) = await _createBoardField(
        tester,
        FieldType.RichText,
        startEditing: false,
      );
      final Finder expand = find.descendant(
        of: _card(card),
        matching: find.byType(OpenCardAccessory),
      );
      final Finder pencil = find.descendant(
        of: _card(card),
        matching: find.byType(EditCardAccessory),
      );
      final Offset outside =
          tester.getRect(_card(card)).topRight + const Offset(8, 8);
      final TestGesture mouse =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: outside);
      try {
        await tester.pumpAndSettle();
        expect(expand, findsNothing);
        expect(pencil, findsNothing);
        await mouse
            .moveTo(tester.getTopLeft(_card(card)) + const Offset(12, 12));
        await tester.pumpAndSettle();
        expect(pencil, findsOneWidget);
        expect(expand, findsNothing);
        await tester.tapButton(pencil, warnIfMissed: true);
        expect(expand, findsOneWidget);
        expect(pencil, findsNothing);
        expect(find.byType(OpenCardAccessory), findsOneWidget);
        expect(
          tester
              .widget<FlowySvg>(
                find.descendant(of: expand, matching: find.byType(FlowySvg)),
              )
              .svg,
          FlowySvgs.full_view_s,
        );
        final Finder accessories = find.descendant(
          of: _card(card),
          matching: find.byType(CardAccessoryContainer),
        );
        expect(
          find.descendant(
            of: accessories,
            matching: find.byType(VerticalDivider),
          ),
          findsNothing,
        );

        await mouse.moveTo(outside);
        await tester.pumpAndSettle();
        expect(expand, findsNothing);
        expect(
          find.descendant(
            of: _card(card),
            matching: find.byType(DoneCardButton),
          ),
          findsOneWidget,
        );
        await mouse.moveTo(
          tester.getTopLeft(_card(card)) + const Offset(12, 12),
        );
        await tester.pumpAndSettle();
        expect(expand, findsOneWidget);
        await _finishCardEditing(tester, card);
        expect(expand, findsNothing);
        expect(pencil, findsOneWidget);
        expect(find.byType(RowDetailPage), findsNothing);
      } finally {
        await mouse.removePointer();
      }
    });

    for (final bool editTitle in [false, true]) {
      testWidgets(
          'expand button saves the active ${editTitle ? 'title' : 'property'} and opens the card',
          (tester) async {
        final (RowCard card, FieldPB description) =
            await _createBoardField(tester, FieldType.RichText);
        final FieldPB field = editTitle
            ? card.fieldController.fieldInfos
                .firstWhere((field) => field.isPrimary)
                .field
            : description;
        if (!editTitle) {
          await tester.tapButton(_property(card, field));
        }
        final Finder input = editTitle
            ? find.descendant(of: _card(card), matching: find.byType(TextField))
            : _propertyInput(card, field);
        const String value = 'Saved by the expand button';
        await tester.enterText(input, value);
        final TestGesture mouse =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: tester.getCenter(_card(card)));
        try {
          await tester.pumpAndSettle();
          final Finder expand = find.descendant(
            of: _card(card),
            matching: find.byType(OpenCardAccessory),
          );
          expect(expand, findsOneWidget);
          await tester.tapButton(expand, warnIfMissed: true);
          expect(find.byType(RowDetailPage), findsOneWidget);
          await _expectSavedText(tester, card, field, value);
          await tester.pumpUntilFound(
            find.descendant(
              of: find.byType(RowDetailPage),
              matching: find.text(value),
            ),
          );
          expect(
            find.descendant(
              of: _card(card),
              matching: find.byType(DoneCardButton),
            ),
            findsNothing,
          );
          expect(expand, findsNothing);
        } finally {
          await mouse.removePointer();
        }
      });
    }

    for (final bool isEditing in [false, true]) {
      testWidgets(
          'empty card space opens the card in ${isEditing ? 'editing' : 'reading'} mode',
          (tester) async {
        final (RowCard card, FieldPB description) = await _createBoardField(
          tester,
          FieldType.RichText,
          startEditing: isEditing,
        );
        const String value = 'Saved before opening the card';
        if (isEditing) {
          await tester.tapButton(_property(card, description));
          await tester.enterText(_propertyInput(card, description), value);
        } else {
          await CellBackendService.updateCell(
            viewId: card.viewId,
            cellContext:
                CellContext(fieldId: description.id, rowId: card.rowMeta.id),
            data: value,
          );
          await tester.pumpUntilFound(
            find.descendant(
              of: _property(card, description),
              matching: find.text(value),
            ),
          );
        }

        final Rect cardRect = tester.getRect(_card(card));
        final Offset emptySpace = cardRect.topLeft + const Offset(2, 2);
        expect(cardRect.contains(emptySpace), isTrue);
        expect(
          tester.getRect(_property(card, description)).contains(emptySpace),
          isFalse,
        );
        await tester.tapAt(emptySpace);
        await tester.pumpAndSettle();
        expect(find.byType(RowDetailPage), findsOneWidget);
        await _expectSavedText(tester, card, description, value);
        await tester.pumpUntilFound(
          find.descendant(
            of: find.byType(RowDetailPage),
            matching: find.text(value),
          ),
        );
        expect(
          find.descendant(
            of: _card(card),
            matching: find.byType(DoneCardButton),
          ),
          findsNothing,
        );
      });

      testWidgets(
          'property clicks do not open the card in ${isEditing ? 'editing' : 'reading'} mode',
          (tester) async {
        final (RowCard card, FieldPB created) = await _createBoardField(
          tester,
          FieldType.CreatedTime,
          startEditing: isEditing,
        );
        final FieldPB completed =
            await _addField(card, FieldType.Checkbox, 'Completed');
        final FieldPB description =
            await _addField(card, FieldType.RichText, 'Description');
        await CellBackendService.updateCell(
          viewId: card.viewId,
          cellContext:
              CellContext(fieldId: description.id, rowId: card.rowMeta.id),
          data: 'Click to edit this property',
        );
        final Finder timestamp = find.descendant(
          of: _card(card),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is TimestampCardCell &&
                widget.cellContext.fieldId == created.id,
          ),
        );
        final Finder timestampText =
            find.descendant(of: timestamp, matching: find.byType(Text));
        await tester.pumpUntilFound(timestampText);
        expect(timestampText, findsOneWidget);
        await tester.tapButton(timestampText, warnIfMissed: true);
        expect(find.byType(RowDetailPage), findsNothing);

        final Finder checkbox = find.descendant(
          of: _card(card),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is CheckboxCardCell &&
                widget.cellContext.fieldId == completed.id,
          ),
        );
        await tester.tapButton(
          find.descendant(of: checkbox, matching: find.text('Completed')),
          warnIfMissed: true,
        );
        expect(find.byType(RowDetailPage), findsNothing);
        await tester.tapButton(
          find.descendant(of: checkbox, matching: find.byType(FlowyIconButton)),
        );
        expect(
          CheckboxCellDataPB.fromBuffer((await _getCell(card, completed)).data)
              .isChecked,
          isTrue,
        );
        expect(find.byType(RowDetailPage), findsNothing);

        await tester.tapButton(_property(card, description));
        final Finder input = _propertyInput(card, description);
        await tester.tapButton(input, warnIfMissed: true);
        expect(find.byType(RowDetailPage), findsNothing);
        await tester.enterText(input, 'Edited without opening the card');
        await tester.tapButton(timestampText, warnIfMissed: true);
        await _expectSavedText(
          tester,
          card,
          description,
          'Edited without opening the card',
        );
        expect(find.byType(RowDetailPage), findsNothing);
        expect(
          find.descendant(
            of: _card(card),
            matching: find.byType(DoneCardButton),
          ),
          isEditing ? findsOneWidget : findsNothing,
        );

        if (!isEditing) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.tapButton(timestampText);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          final BoardFocusScope focusScope = tester
              .widget<BoardShortcutContainer>(
                find.byType(BoardShortcutContainer),
              )
              .focusScope;
          expect(
            focusScope.focusedGroupedRows.map((row) => row.rowId),
            contains(card.rowMeta.id),
          );
          expect(find.byType(RowDetailPage), findsNothing);
        }
      });
    }

    for (final bool useDone in [true, false]) {
      testWidgets(
          'click the title to edit and save with ${useDone ? 'Done' : 'an outside click'}',
          (tester) async {
        final (RowCard card, FieldPB description) =
            await _createBoardField(tester, FieldType.RichText);
        final FieldPB title = card.fieldController.fieldInfos
            .firstWhere((field) => field.isPrimary)
            .field;
        final Finder titleInput = find.descendant(
          of: _card(card),
          matching: find.descendant(
            of: find.byWidgetPredicate(
              (widget) =>
                  widget is TextCardCell &&
                  widget.cellContext.fieldId == title.id,
            ),
            matching: find.byType(TextField),
          ),
        );

        // Losing title focus to another property must not make title clicks
        // open the row detail while the card is still being edited.
        await tester.tapButton(_property(card, description));
        await tester.enterText(
          _propertyInput(card, description),
          'Keep editing',
        );
        await tester.tapButton(titleInput, warnIfMissed: true);
        expect(find.byType(RowDetailPage), findsNothing);
        expect(tester.widget<TextField>(titleInput).readOnly, isFalse);
        expect(
          tester.widget<TextField>(titleInput).focusNode!.hasFocus,
          isTrue,
        );
        expect(
          tester.widget<TextField>(titleInput).enableInteractiveSelection,
          isTrue,
        );
        await tester.enterText(titleInput, 'Title edited on the board');

        // Returning from a popup must also leave the title clickable.
        await _pressTab(tester);
        expect(find.byType(SelectOptionCellEditor), findsOneWidget);
        await tester.dismissCellEditor();
        await tester.tapButton(titleInput, warnIfMissed: true);
        expect(find.byType(RowDetailPage), findsNothing);
        expect(
          tester.widget<TextField>(titleInput).focusNode!.hasFocus,
          isTrue,
        );
        await tester.enterText(titleInput, 'Title edited again');
        if (useDone) {
          await _finishCardEditing(tester, card);
        } else {
          await _tapOutsideCard(tester, card);
        }
        await _expectSavedText(tester, card, title, 'Title edited again');
        await _expectSavedText(tester, card, description, 'Keep editing');
        expect(tester.widget<TextField>(titleInput).readOnly, isTrue);
        expect(
          find.descendant(
            of: _card(card),
            matching: find.byType(DoneCardButton),
          ),
          findsNothing,
        );
        expect(find.byType(RowDetailPage), findsNothing);

        // Reading mode retains the normal title-to-open behavior.
        // The title input deliberately ignores pointers in reading mode, so
        // this tap is handled by the surrounding card instead.
        await tester.tapButton(titleInput);
        expect(find.byType(RowDetailPage), findsOneWidget);
      });
    }

    testWidgets('click an empty title to resume editing after Enter',
        (tester) async {
      final (RowCard card, FieldPB _) =
          await _createBoardField(tester, FieldType.RichText);
      final FieldPB title = card.fieldController.fieldInfos
          .firstWhere((field) => field.isPrimary)
          .field;
      final Finder titleInput = find.descendant(
        of: _card(card),
        matching: find.byType(TextField),
      );
      await tester.enterText(titleInput, '');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await _expectSavedText(tester, card, title, '');
      await tester.tapButton(titleInput, warnIfMissed: true);
      expect(tester.widget<TextField>(titleInput).focusNode!.hasFocus, isTrue);
      expect(find.byType(RowDetailPage), findsNothing);
      await tester.enterText(titleInput, 'Restored title');
      await _finishCardEditing(tester, card);
      await _expectSavedText(tester, card, title, 'Restored title');
    });

    testWidgets('Tab and Shift Tab save and edit fields in card order',
        (tester) async {
      final (RowCard card, FieldPB description) =
          await _createBoardField(tester, FieldType.RichText);
      final FieldPB effort = await _addField(card, FieldType.Number, 'Effort');
      final FieldPB link = await _addField(card, FieldType.URL, 'Link');
      final FieldPB time = await _addField(card, FieldType.Time, 'Time');
      await tester.pumpAndSettle();

      await tester.tapButton(_property(card, description));
      await tester.enterText(
        _propertyInput(card, description),
        'Keyboard edit',
      );
      await _pressTab(tester);
      _expectPropertyFocus(tester, card, effort);
      await tester.enterText(_propertyInput(card, effort), '8');

      await _pressTab(tester, reverse: true);
      _expectPropertyFocus(tester, card, description);
      expect(
        tester
            .widget<TextField>(_propertyInput(card, description))
            .controller!
            .text,
        'Keyboard edit',
      );
      await _expectSavedText(tester, card, description, 'Keyboard edit');
      await _expectSavedText(tester, card, effort, '8');

      await _pressTab(tester);
      await _pressTab(tester);
      _expectPropertyFocus(tester, card, link);
      await tester.enterText(_propertyInput(card, link), 'https://appflowy.io');
      await _pressTab(tester);
      _expectPropertyFocus(tester, card, time);
      await _expectSavedText(tester, card, link, 'https://appflowy.io');

      // The last field leads to Done; Shift+Tab reopens that last field.
      await _pressTab(tester);
      final Finder done = find.descendant(
        of: _card(card),
        matching: find.byType(DoneCardButton),
      );
      expect(tester.widget<DoneCardButton>(done).focusNode!.hasFocus, isTrue);
      await _pressTab(tester, reverse: true);
      _expectPropertyFocus(tester, card, time);
      expect(done, findsOneWidget);
      expect(find.byType(RowDetailPage), findsNothing);
    });

    testWidgets('Tab navigates from the title through the grouping popup',
        (tester) async {
      final (RowCard card, FieldPB description) =
          await _createBoardField(tester, FieldType.RichText);
      final FieldPB title = card.fieldController.fieldInfos
          .firstWhere((field) => field.isPrimary)
          .field;
      final Finder titleInput = find.descendant(
        of: _card(card),
        matching: find.byType(TextField),
      );
      await tester.enterText(titleInput, 'Renamed with Tab');
      await _pressTab(tester);
      expect(find.byType(SelectOptionCellEditor), findsOneWidget);
      await _pressTab(tester, reverse: true);
      expect(find.byType(SelectOptionCellEditor), findsNothing);
      expect(tester.widget<TextField>(titleInput).readOnly, isFalse);
      expect(tester.widget<TextField>(titleInput).focusNode!.hasFocus, isTrue);
      await _expectSavedText(tester, card, title, 'Renamed with Tab');

      await _pressTab(tester);
      await _pressTab(tester);
      _expectPropertyFocus(tester, card, description);
      expect(find.byType(SelectOptionCellEditor), findsNothing);
      expect(find.byType(RowDetailPage), findsNothing);
    });

    testWidgets('Tab skips read-only fields and focuses checkbox properties',
        (tester) async {
      final (RowCard card, FieldPB effort) =
          await _createBoardField(tester, FieldType.Number);
      await _addField(card, FieldType.CreatedTime, 'Created');
      final FieldPB completed =
          await _addField(card, FieldType.Checkbox, 'Completed');
      final FieldPB description =
          await _addField(card, FieldType.RichText, 'Description');
      await tester.pumpAndSettle();
      await tester.tapButton(_property(card, effort));
      await tester.enterText(_propertyInput(card, effort), '3');
      await _pressTab(tester);

      final CheckboxCardCell checkbox = tester.widget<CheckboxCardCell>(
        find.descendant(
          of: _card(card),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is CheckboxCardCell &&
                widget.cellContext.fieldId == completed.id,
          ),
        ),
      );
      expect(checkbox.focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        CheckboxCellDataPB.fromBuffer((await _getCell(card, completed)).data)
            .isChecked,
        isTrue,
      );
      await _pressTab(tester);
      _expectPropertyFocus(tester, card, description);
      await _pressTab(tester, reverse: true);
      expect(checkbox.focusNode!.hasFocus, isTrue);
      await _pressTab(tester, reverse: true);
      _expectPropertyFocus(tester, card, effort);
      await _expectSavedText(tester, card, effort, '3');
    });

    for (final (FieldType fieldType, Type editorType) in [
      (FieldType.DateTime, DateCellEditor),
      (FieldType.Checklist, ChecklistCellEditor),
      (FieldType.Media, MediaCellEditor),
      (FieldType.Relation, RelationCellEditor),
    ]) {
      testWidgets('Tab leaves the $fieldType popup and Shift Tab reopens it',
          (tester) async {
        final (RowCard card, FieldPB field) =
            await _createBoardField(tester, fieldType);
        final FieldPB effort =
            await _addField(card, FieldType.Number, 'Effort');
        await tester.pumpAndSettle();
        await tester.tapButton(_property(card, field));
        expect(find.byType(editorType), findsOneWidget);
        if (fieldType == FieldType.DateTime) {
          await tester.selectDay(content: DateTime.now().day);
        }

        await _pressTab(tester);
        expect(find.byType(editorType), findsNothing);
        _expectPropertyFocus(tester, card, effort);
        await tester.enterText(_propertyInput(card, effort), '5');
        await _pressTab(tester, reverse: true);
        expect(find.byType(editorType), findsOneWidget);
        expect(
          tester
              .widget<BoardCardCell>(_property(card, field))
              .focusNode!
              .hasFocus,
          isTrue,
        );
        await _expectSavedText(tester, card, effort, '5');
        if (fieldType == FieldType.DateTime) {
          expect(
            DateCellDataPB.fromBuffer((await _getCell(card, field)).data)
                .hasTimestamp(),
            isTrue,
          );
        }
        expect(find.byType(RowDetailPage), findsNothing);
      });
    }

    testWidgets('Done saves filled fields and hides fields left empty',
        (tester) async {
      final (RowCard card, FieldPB description) = await _createBoardField(
        tester,
        FieldType.RichText,
        startEditing: false,
      );
      final FieldPB effort = await _addField(card, FieldType.Number, 'Effort');
      final FieldPB reference =
          await _addField(card, FieldType.URL, 'Reference');
      await tester.pumpAndSettle();
      for (final FieldPB field in [description, effort, reference]) {
        expect(
          find.descendant(
            of: _property(card, field),
            matching: find.text(field.name),
          ),
          findsNothing,
        );
      }

      await _beginCardEditing(tester, card);
      for (final FieldPB field in [description, effort, reference]) {
        expect(
          find.descendant(
            of: _property(card, field),
            matching: find.text(field.name),
          ),
          findsOneWidget,
        );
      }

      final Finder descriptionProperty = _property(card, description);
      await tester.tapButton(descriptionProperty);
      await tester.enterText(
        find.descendant(
          of: descriptionProperty,
          matching: find.byType(TextField),
        ),
        'Written on the board',
      );
      final Finder effortProperty = _property(card, effort);
      await tester.tapButton(effortProperty);
      await tester.enterText(
        find.descendant(of: effortProperty, matching: find.byType(TextField)),
        '7',
      );
      // Moving away from the title or another property must keep the card open
      // for editing. Done must also save the currently focused property.
      expect(
        find.descendant(
          of: _property(card, reference),
          matching: find.text(reference.name),
        ),
        findsOneWidget,
      );
      await _finishCardEditing(tester, card);
      await tester.pumpUntilFound(
        find.descendant(of: effortProperty, matching: find.text('7')),
      );
      expect(
        utf8.decode((await _getCell(card, description)).data),
        'Written on the board',
      );
      expect(utf8.decode((await _getCell(card, effort)).data), '7');
      expect(
        find.descendant(
          of: _property(card, reference),
          matching: find.text(reference.name),
        ),
        findsNothing,
      );
      expect(find.byType(RowDetailPage), findsNothing);

      await _beginCardEditing(tester, card);
      expect(
        find.descendant(
          of: _property(card, reference),
          matching: find.text(reference.name),
        ),
        findsOneWidget,
      );
      await tester.tapButton(descriptionProperty, warnIfMissed: true);
      final Finder reopenedInput = find.descendant(
        of: descriptionProperty,
        matching: find.byType(TextField),
      );
      expect(reopenedInput, findsOneWidget);
      await tester.enterText(reopenedInput, '');
      await _finishCardEditing(tester, card);
      expect(utf8.decode((await _getCell(card, description)).data), '');
      expect(
        find.descendant(
          of: descriptionProperty,
          matching: find.text(description.name),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: effortProperty, matching: find.text('7')),
        findsOneWidget,
      );
    });

    for (final (FieldType fieldType, String value) in [
      (FieldType.RichText, 'Saved by clicking outside'),
      (FieldType.Number, '12'),
    ]) {
      testWidgets('outside click saves $fieldType and finishes card editing',
          (tester) async {
        final (RowCard card, FieldPB field) =
            await _createBoardField(tester, fieldType);
        final FieldPB emptyField =
            await _addField(card, FieldType.URL, 'Reference');
        await tester.pumpAndSettle();
        final Finder property = _property(card, field);
        await tester.tapButton(property);
        await tester.enterText(
          find.descendant(of: property, matching: find.byType(TextField)),
          value,
        );

        await _tapOutsideCard(tester, card);
        await _expectSavedText(tester, card, field, value);
        await tester.pumpUntilFound(
          find.descendant(of: property, matching: find.text(value)),
        );
        expect(
          find.descendant(
            of: _card(card),
            matching: find.byType(DoneCardButton),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: _property(card, emptyField),
            matching: find.text(emptyField.name),
          ),
          findsNothing,
        );
        expect(find.byType(RowDetailPage), findsNothing);

        // Clearing the focused field must also save before the empty value
        // disappears from reading mode.
        await _beginCardEditing(tester, card);
        await tester.tapButton(property);
        await tester.enterText(
          find.descendant(of: property, matching: find.byType(TextField)),
          '',
        );
        await _tapOutsideCard(tester, card);
        await _expectSavedText(tester, card, field, '');
        expect(
          find.descendant(of: property, matching: find.text(field.name)),
          findsNothing,
        );
      });
    }

    testWidgets('outside clicks save the date before finishing card editing',
        (tester) async {
      final (RowCard card, FieldPB field) =
          await _createBoardField(tester, FieldType.DateTime);
      final FieldPB emptyField =
          await _addField(card, FieldType.URL, 'Reference');
      await tester.pumpAndSettle();
      final Finder property = _property(card, field);
      await tester.tapButton(property);
      expect(find.byType(DateCellEditor), findsOneWidget);
      await tester.selectDay(content: DateTime.now().day);

      // Both clicks are outside the card, not just outside the date picker.
      await _tapOutsideCard(tester, card);
      expect(find.byType(DateCellEditor), findsNothing);
      expect(
        find.descendant(of: _card(card), matching: find.byType(DoneCardButton)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _property(card, emptyField),
          matching: find.text(emptyField.name),
        ),
        findsOneWidget,
      );
      final DateCellDataPB savedDate =
          DateCellDataPB.fromBuffer((await _getCell(card, field)).data);
      expect(savedDate.hasTimestamp(), isTrue);

      await _tapOutsideCard(tester, card);
      expect(
        find.descendant(of: _card(card), matching: find.byType(DoneCardButton)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: _property(card, emptyField),
          matching: find.text(emptyField.name),
        ),
        findsNothing,
      );
      expect(
        DateCellDataPB.fromBuffer((await _getCell(card, field)).data).timestamp,
        savedDate.timestamp,
      );
      expect(find.byType(RowDetailPage), findsNothing);
    });

    testWidgets('editing another card finishes the previous card session',
        (tester) async {
      final (RowCard firstCard, FieldPB field) =
          await _createBoardField(tester, FieldType.RichText);
      final RowCard secondCard = tester.widget<RowCard>(
        find.ancestor(of: find.text('Card 2'), matching: find.byType(RowCard)),
      );
      await _beginCardEditing(tester, secondCard);
      expect(
        find.descendant(
          of: _card(firstCard),
          matching: find.byType(DoneCardButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: _property(firstCard, field),
          matching: find.text(field.name),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: _property(secondCard, field),
          matching: find.text(field.name),
        ),
        findsOneWidget,
      );
      await _finishCardEditing(tester, secondCard);
    });

    testWidgets('the grouping property can be changed during editing',
        (tester) async {
      final (RowCard card, FieldPB _) =
          await _createBoardField(tester, FieldType.RichText);
      final FieldPB status = card.fieldController.fieldInfos
          .firstWhere((field) => field.id == card.groupingFieldId)
          .field;
      await tester.tapButton(_property(card, status));
      await tester.selectOption(name: 'Doing');
      await tester.pumpAndSettle();
      expect(
        SelectOptionCellDataPB.fromBuffer((await _getCell(card, status)).data)
            .selectOptions
            .map((option) => option.name),
        ['Doing'],
      );
      expect(find.byType(RowDetailPage), findsNothing);
      expect(
        find.descendant(of: _card(card), matching: find.byType(DoneCardButton)),
        findsNothing,
      );
    });

    for (final (FieldType fieldType, String value) in [
      (FieldType.RichText, 'Description edited on the board'),
      (FieldType.Number, '42'),
    ]) {
      testWidgets('edit and clear $fieldType without opening the card',
          (tester) async {
        final (RowCard card, FieldPB field) =
            await _createBoardField(tester, fieldType);
        final Finder property = _property(card, field);

        expect(
          find.descendant(of: property, matching: find.text(field.name)),
          findsOneWidget,
        );
        await tester.tapButton(property);
        expect(find.byType(RowDetailPage), findsNothing);

        final Finder input = find.descendant(
          of: property,
          matching: find.byType(TextField),
        );
        await tester.enterText(input, value);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        await tester.pumpUntilFound(
          find.descendant(of: property, matching: find.text(value)),
        );

        expect(utf8.decode((await _getCell(card, field)).data), value);
        expect(find.byType(RowDetailPage), findsNothing);

        // Reopening the editor must load the saved value, and clearing it must
        // restore the editable placeholder rather than removing the property.
        await tester.tapButton(property);
        expect(tester.widget<TextField>(input).controller!.text, value);
        await tester.enterText(input, '');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.pumpUntilFound(
          find.descendant(of: property, matching: find.text(field.name)),
        );
        expect(utf8.decode((await _getCell(card, field)).data), '');

        await _finishCardEditing(tester, card);
        expect(
          find.descendant(of: property, matching: find.text(field.name)),
          findsNothing,
        );
        await _beginCardEditing(tester, card);
        expect(
          find.descendant(of: property, matching: find.text(field.name)),
          findsOneWidget,
        );
        await _finishCardEditing(tester, card);

        // The title/card still opens the complete row when requested.
        await tester.tapButton(
          find.descendant(
            of: _card(card),
            matching: find.text('Card 1'),
          ),
        );
        expect(find.byType(RowDetailPage), findsOneWidget);
      });
    }

    for (final FieldType fieldType in [
      FieldType.SingleSelect,
      FieldType.MultiSelect,
    ]) {
      testWidgets('edit $fieldType from the board', (tester) async {
        final (RowCard card, FieldPB field) =
            await _createBoardField(tester, fieldType);
        final Finder property = _property(card, field);

        await tester.tapButton(property);
        expect(find.byType(SelectOptionCellEditor), findsOneWidget);
        expect(find.byType(RowDetailPage), findsNothing);

        await tester.createOption(name: 'Urgent');
        await tester.dismissCellEditor();
        await tester.pumpUntilFound(
          find.descendant(of: property, matching: find.text('Urgent')),
        );

        final SelectOptionCellDataPB data = SelectOptionCellDataPB.fromBuffer(
          (await _getCell(card, field)).data,
        );
        expect(data.selectOptions.map((option) => option.name), ['Urgent']);
        expect(find.byType(RowDetailPage), findsNothing);

        await tester.tapButton(property);
        await tester.selectOption(name: 'Urgent');
        await tester.dismissCellEditor();
        await tester.pumpUntilFound(
          find.descendant(of: property, matching: find.text(field.name)),
        );
        expect(
          SelectOptionCellDataPB.fromBuffer((await _getCell(card, field)).data)
              .selectOptions,
          isEmpty,
        );
      });
    }

    testWidgets('set and clear a date from the board', (tester) async {
      final (RowCard card, FieldPB field) =
          await _createBoardField(tester, FieldType.DateTime);
      final Finder property = _property(card, field);

      await tester.tapButton(property);
      expect(find.byType(DateCellEditor), findsOneWidget);
      expect(find.byType(RowDetailPage), findsNothing);
      await tester.selectDay(content: DateTime.now().day);
      await tester.dismissCellEditor();

      final DateCellDataPB data =
          DateCellDataPB.fromBuffer((await _getCell(card, field)).data);
      expect(data.hasTimestamp(), isTrue);
      expect(find.byType(RowDetailPage), findsNothing);

      await tester.tapButton(property);
      await tester.clearDate();
      await tester.dismissCellEditor();
      await tester.pumpUntilFound(
        find.descendant(of: property, matching: find.text(field.name)),
      );
    });

    testWidgets('show empty properties only during the card edit session',
        (tester) async {
      final (RowCard card, FieldPB field) = await _createBoardField(
        tester,
        FieldType.RichText,
        startEditing: false,
      );
      final FieldSettingsBackendService settings =
          FieldSettingsBackendService(viewId: card.viewId);
      expect(
        find.descendant(
          of: _property(card, field),
          matching: find.text(field.name),
        ),
        findsNothing,
      );

      await settings.updateFieldSettings(
        fieldId: field.id,
        fieldVisibility: FieldVisibility.HideWhenEmpty,
      );
      await tester.pumpAndSettle();
      await _beginCardEditing(tester, card);
      expect(
        find.descendant(
          of: _property(card, field),
          matching: find.text(field.name),
        ),
        findsOneWidget,
      );

      await settings.updateFieldSettings(
        fieldId: field.id,
        fieldVisibility: FieldVisibility.AlwaysHidden,
      );
      await tester.pumpAndSettle();
      expect(_property(card, field), findsOneWidget);
      await _finishCardEditing(tester, card);
      expect(_property(card, field), findsNothing);

      // Edit also exposes properties that have been hidden from reading mode.
      await _beginCardEditing(tester, card);
      expect(
        find.descendant(
          of: _property(card, field),
          matching: find.text(field.name),
        ),
        findsOneWidget,
      );
      await _finishCardEditing(tester, card);

      await settings.updateFieldSettings(
        fieldId: field.id,
        fieldVisibility: FieldVisibility.AlwaysShown,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _property(card, field),
          matching: find.text(field.name),
        ),
        findsNothing,
      );
    });

    testWidgets('timestamps have no inline editor', (tester) async {
      final (RowCard card, FieldPB field) =
          await _createBoardField(tester, FieldType.CreatedTime);
      expect(_property(card, field), findsNothing);
    });

    for (final (FieldType fieldType, Type editorType) in [
      (FieldType.Checklist, ChecklistCellEditor),
      (FieldType.Media, MediaCellEditor),
      (FieldType.Relation, RelationCellEditor),
    ]) {
      testWidgets('open the $fieldType editor from the board', (tester) async {
        final (RowCard card, FieldPB field) =
            await _createBoardField(tester, fieldType);
        await tester.tapButton(_property(card, field));
        expect(find.byType(editorType), findsOneWidget);
        expect(find.byType(RowDetailPage), findsNothing);
        // Click outside the popup to return to the board.
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        expect(find.byType(editorType), findsNothing);
      });
    }

    testWidgets('checkboxes remain editable without opening the card',
        (tester) async {
      final (RowCard card, FieldPB field) =
          await _createBoardField(tester, FieldType.Checkbox);
      final Finder checkbox = find.descendant(
        of: _card(card),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CheckboxCardCell &&
              widget.cellContext.fieldId == field.id,
        ),
      );
      await tester.tapButton(
        find.descendant(of: checkbox, matching: find.byType(FlowyIconButton)),
      );
      expect(
        CheckboxCellDataPB.fromBuffer((await _getCell(card, field)).data)
            .isChecked,
        isTrue,
      );
      expect(find.byType(RowDetailPage), findsNothing);
    });

    testWidgets('property gestures preserve card selection and dragging',
        (tester) async {
      final (RowCard card, FieldPB field) = await _createBoardField(
        tester,
        FieldType.Number,
        startEditing: false,
      );
      await CellBackendService.updateCell(
        viewId: card.viewId,
        cellContext: CellContext(fieldId: field.id, rowId: card.rowMeta.id),
        data: '42',
      );
      final Finder property = _property(card, field);
      await tester.pumpUntilFound(
        find.descendant(of: property, matching: find.text('42')),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tapButton(property);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      final BoardFocusScope focusScope = tester
          .widget<BoardShortcutContainer>(find.byType(BoardShortcutContainer))
          .focusScope;
      expect(
        focusScope.focusedGroupedRows.map((row) => row.rowId),
        contains(card.rowMeta.id),
      );
      expect(
        find.descendant(of: property, matching: find.byType(TextField)),
        findsNothing,
      );
      expect(find.byType(RowDetailPage), findsNothing);

      final Offset target = tester.getCenter(find.text('Doing'));
      await tester.timedDrag(
        property,
        target - tester.getCenter(property),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      await tester.tapButton(
        find.descendant(of: _card(card), matching: find.text('Card 1')),
      );
      expect(
        find.descendant(
          of: find.byType(RowPropertyList),
          matching: find.text('Doing'),
        ),
        findsOneWidget,
      );
    });
  });
}

Finder _propertyInput(RowCard card, FieldPB field) => find.descendant(
      of: _property(card, field),
      matching: find.byType(TextField),
    );

void _expectPropertyFocus(WidgetTester tester, RowCard card, FieldPB field) {
  expect(
    tester.widget<BoardCardCell>(_property(card, field)).focusNode!.hasFocus,
    isTrue,
  );
  expect(
    tester.widget<TextField>(_propertyInput(card, field)).focusNode!.hasFocus,
    isTrue,
  );
}

Future<void> _pressTab(WidgetTester tester, {bool reverse = false}) async {
  if (reverse) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (reverse) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.pumpAndSettle();
}

Finder _card(RowCard card) => find.byWidgetPredicate(
      (widget) => widget is RowCard && widget.rowMeta.id == card.rowMeta.id,
    );

Finder _property(RowCard card, FieldPB field) => find.descendant(
      of: _card(card),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is BoardCardCell && widget.cellContext.fieldId == field.id,
      ),
    );

Future<(RowCard, FieldPB)> _createBoardField(
  WidgetTester tester,
  FieldType fieldType, {
  bool startEditing = true,
}) async {
  await tester.initializeAppFlowy();
  await tester.tapAnonymousSignInButton();
  await tester.pumpUntilFound(tester.findPageName(gettingStarted));
  await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

  final RowCard card = tester.widget<RowCard>(
    find.ancestor(
      of: find.text('Card 1'),
      matching: find.byType(RowCard),
    ),
  );
  final FlowyResult<FieldPB, FlowyError> result =
      await FieldBackendService.createField(
    viewId: card.viewId,
    fieldType: fieldType,
    fieldName: 'Inline ${fieldType.name}',
  );
  final FieldPB field = result.fold(
    (field) => field,
    (error) => throw TestFailure('Create property: $error'),
  );
  final FlowyResult<void, FlowyError> settings =
      await FieldSettingsBackendService(viewId: card.viewId)
          .updateFieldSettings(
    fieldId: field.id,
    fieldVisibility: FieldVisibility.AlwaysShown,
  );
  settings.fold(
    (_) {},
    (error) => throw TestFailure('Show property: $error'),
  );
  await tester.pumpAndSettle();
  if (startEditing) {
    await _beginCardEditing(tester, card);
  }
  return (card, field);
}

Future<void> _beginCardEditing(WidgetTester tester, RowCard card) async {
  await tester.hoverOnWidget(
    _card(card),
    onHover: () async {
      await tester.tapButton(
        find.descendant(
          of: _card(card),
          matching: find.byType(EditCardAccessory),
        ),
      );
    },
  );
  expect(
    find.descendant(of: _card(card), matching: find.byType(DoneCardButton)),
    findsOneWidget,
  );
}

Future<void> _finishCardEditing(WidgetTester tester, RowCard card) async {
  await tester.tapButton(
    find.descendant(of: _card(card), matching: find.byType(DoneCardButton)),
  );
  await tester.pumpAndSettle();
  expect(
    find.descendant(of: _card(card), matching: find.byType(DoneCardButton)),
    findsNothing,
  );
}

Future<void> _tapOutsideCard(WidgetTester tester, RowCard card) async {
  final Rect cardRect = tester.getRect(_card(card));
  final Offset outside = cardRect.topRight + const Offset(8, 8);
  expect(cardRect.contains(outside), isFalse);
  await tester.tapAt(outside);
  await tester.pumpAndSettle();
}

Future<void> _expectSavedText(
  WidgetTester tester,
  RowCard card,
  FieldPB field,
  String expected,
) async {
  // Text saves are debounced. Wait for persistence rather than relying on
  // animations settling, which can finish before the save timer fires.
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 10));
  String content(CellPB cell) => field.fieldType == FieldType.URL
      ? URLCellDataPB.fromBuffer(cell.data).content
      : utf8.decode(cell.data);
  var actual = content(await _getCell(card, field));
  while (actual != expected && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    actual = content(await _getCell(card, field));
  }
  expect(actual, expected);
}

Future<CellPB> _getCell(RowCard card, FieldPB field) async {
  final FlowyResult<CellPB, FlowyError> result =
      await CellBackendService.getCell(
    viewId: card.viewId,
    cellContext: CellContext(fieldId: field.id, rowId: card.rowMeta.id),
  );
  return result.fold(
    (cell) => cell,
    (error) => throw TestFailure('Load saved property: $error'),
  );
}

Future<FieldPB> _addField(RowCard card, FieldType type, String name) async {
  final FlowyResult<FieldPB, FlowyError> result =
      await FieldBackendService.createField(
    viewId: card.viewId,
    fieldType: type,
    fieldName: name,
  );
  return result.fold(
    (field) => field,
    (error) => throw TestFailure('Create property: $error'),
  );
}

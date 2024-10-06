import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/domain/field_settings_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest cellTest;

  setUpAll(() async {
    cellTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('text cell bloc:', () {
    late GridTestContext context;
    late TextCellController cellController;

    setUp(() async {
      context = await cellTest.makeDefaultTestGrid();
      await RowBackendService.createRow(viewId: context.view.id);
      final fieldIndex = context.fieldController.fieldInfos
          .indexWhere((field) => field.fieldType == FieldType.RichText);
      cellController = context.makeGridCellController(fieldIndex, 0).as();
    });

    test('update text', () async {
      final bloc = TextCellBloc(cellController: cellController);
      await gridResponseFuture();

      expect(bloc.state.content, "");

      bloc.add(const TextCellEvent.updateText("A"));
      await gridResponseFuture(milliseconds: 600);

      expect(bloc.state.content, "A");
    });

    test('non-primary text field emoji and hasDocument', () async {
      final primaryBloc = TextCellBloc(cellController: cellController);
      expect(primaryBloc.state.emoji == null, false);
      expect(primaryBloc.state.hasDocument == null, false);

      await primaryBloc.close();

      await FieldBackendService.createField(
        viewId: context.view.id,
        fieldName: "Second",
      );
      await gridResponseFuture();
      final fieldIndex = context.fieldController.fieldInfos.indexWhere(
        (field) => field.fieldType == FieldType.RichText && !field.isPrimary,
      );
      cellController = context.makeGridCellController(fieldIndex, 0).as();
      final nonPrimaryBloc = TextCellBloc(cellController: cellController);
      await gridResponseFuture();

      expect(nonPrimaryBloc.state.emoji == null, true);
      expect(nonPrimaryBloc.state.hasDocument == null, true);
    });

    test('update wrap cell content', () async {
      final bloc = TextCellBloc(cellController: cellController);
      await gridResponseFuture();

      expect(bloc.state.wrap, true);

      await FieldSettingsBackendService(
        viewId: context.view.id,
      ).updateFieldSettings(
        fieldId: cellController.fieldId,
        wrapCellContent: false,
      );
      await gridResponseFuture();

      expect(bloc.state.wrap, false);
    });

    test('update emoji', () async {
      final bloc = TextCellBloc(cellController: cellController);
      await gridResponseFuture();

      expect(bloc.state.emoji!.value, "");

      await RowBackendService(viewId: context.view.id)
          .updateMeta(rowId: cellController.rowId, iconURL: "dummy");
      await gridResponseFuture();

      expect(bloc.state.emoji!.value, "dummy");
    });

    test('update document data', () async {
      // This is so fake?
      final bloc = TextCellBloc(cellController: cellController);
      await gridResponseFuture();

      expect(bloc.state.hasDocument!.value, false);

      await RowBackendService(viewId: context.view.id)
          .updateMeta(rowId: cellController.rowId, isDocumentEmpty: false);
      await gridResponseFuture();

      expect(bloc.state.hasDocument!.value, true);
    });
  });
}

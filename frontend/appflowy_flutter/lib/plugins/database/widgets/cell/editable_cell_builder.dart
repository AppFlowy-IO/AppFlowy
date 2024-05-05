import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

import '../row/accessory/cell_accessory.dart';
import '../row/accessory/cell_shortcuts.dart';
import '../row/cells/cell_container.dart';

import 'editable_cell_skeleton/checkbox.dart';
import 'editable_cell_skeleton/checklist.dart';
import 'editable_cell_skeleton/date.dart';
import 'editable_cell_skeleton/number.dart';
import 'editable_cell_skeleton/relation.dart';
import 'editable_cell_skeleton/select_option.dart';
import 'editable_cell_skeleton/summary.dart';
import 'editable_cell_skeleton/text.dart';
import 'editable_cell_skeleton/timestamp.dart';
import 'editable_cell_skeleton/url.dart';

enum EditableCellStyle {
  desktopGrid,
  desktopRowDetail,
  mobileGrid,
  mobileRowDetail,
}

/// Build an editable cell widget
class EditableCellBuilder {
  EditableCellBuilder({required this.databaseController});

  final DatabaseController databaseController;

  EditableCellWidget buildStyled(
    CellContext cellContext,
    EditableCellStyle style,
  ) {
    final fieldType = databaseController.fieldController
        .getField(cellContext.fieldId)!
        .fieldType;
    final key = ValueKey(
      "${databaseController.viewId}${cellContext.fieldId}${cellContext.rowId}",
    );
    return switch (fieldType) {
      FieldType.Checkbox => EditableCheckboxCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableCheckboxCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.Checklist => EditableChecklistCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableChecklistCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.CreatedTime => EditableTimestampCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableTimestampCellSkin.fromStyle(style),
          key: key,
          fieldType: FieldType.CreatedTime,
        ),
      FieldType.DateTime => EditableDateCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableDateCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.LastEditedTime => EditableTimestampCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableTimestampCellSkin.fromStyle(style),
          key: key,
          fieldType: FieldType.LastEditedTime,
        ),
      FieldType.MultiSelect => EditableSelectOptionCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableSelectOptionCellSkin.fromStyle(style),
          key: key,
          fieldType: FieldType.MultiSelect,
        ),
      FieldType.Number => EditableNumberCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableNumberCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.RichText => EditableTextCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableTextCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.SingleSelect => EditableSelectOptionCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableSelectOptionCellSkin.fromStyle(style),
          key: key,
          fieldType: FieldType.SingleSelect,
        ),
      FieldType.URL => EditableURLCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableURLCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.Relation => EditableRelationCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableRelationCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.Summary => EditableSummaryCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: IEditableSummaryCellSkin.fromStyle(style),
          key: key,
        ),
      _ => throw UnimplementedError(),
    };
  }

  EditableCellWidget buildCustom(
    CellContext cellContext, {
    required EditableCellSkinMap skinMap,
  }) {
    final DatabaseController(:fieldController) = databaseController;
    final fieldType = fieldController.getField(cellContext.fieldId)!.fieldType;

    final key = ValueKey(
      "${databaseController.viewId}${cellContext.fieldId}${cellContext.rowId}",
    );
    assert(skinMap.has(fieldType));
    return switch (fieldType) {
      FieldType.Checkbox => EditableCheckboxCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.checkboxSkin!,
          key: key,
        ),
      FieldType.Checklist => EditableChecklistCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.checklistSkin!,
          key: key,
        ),
      FieldType.CreatedTime => EditableTimestampCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.timestampSkin!,
          key: key,
          fieldType: FieldType.CreatedTime,
        ),
      FieldType.DateTime => EditableDateCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.dateSkin!,
          key: key,
        ),
      FieldType.LastEditedTime => EditableTimestampCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.timestampSkin!,
          key: key,
          fieldType: FieldType.LastEditedTime,
        ),
      FieldType.MultiSelect => EditableSelectOptionCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.selectOptionSkin!,
          key: key,
          fieldType: FieldType.MultiSelect,
        ),
      FieldType.Number => EditableNumberCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.numberSkin!,
          key: key,
        ),
      FieldType.RichText => EditableTextCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.textSkin!,
          key: key,
        ),
      FieldType.SingleSelect => EditableSelectOptionCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.selectOptionSkin!,
          key: key,
          fieldType: FieldType.SingleSelect,
        ),
      FieldType.URL => EditableURLCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.urlSkin!,
          key: key,
        ),
      FieldType.Relation => EditableRelationCell(
          databaseController: databaseController,
          cellContext: cellContext,
          skin: skinMap.relationSkin!,
          key: key,
        ),
      _ => throw UnimplementedError(),
    };
  }
}

abstract class CellEditable {
  SingleListenerChangeNotifier get requestFocus;

  CellContainerNotifier get cellContainerNotifier;
}

typedef AccessoryBuilder = List<GridCellAccessoryBuilder> Function(
  GridCellAccessoryBuildContext buildContext,
);

abstract class CellAccessory extends Widget {
  const CellAccessory({super.key});

  AccessoryBuilder? get accessoryBuilder;
}

abstract class EditableCellWidget extends StatefulWidget
    implements CellAccessory, CellEditable, CellShortcuts {
  EditableCellWidget({super.key});

  @override
  final CellContainerNotifier cellContainerNotifier = CellContainerNotifier();

  @override
  AccessoryBuilder? get accessoryBuilder => null;

  @override
  final requestFocus = SingleListenerChangeNotifier();

  @override
  final Map<CellKeyboardKey, CellKeyboardAction> shortcutHandlers = {};
}

abstract class GridCellState<T extends EditableCellWidget> extends State<T> {
  @override
  void initState() {
    super.initState();
    widget.requestFocus.addListener(onRequestFocus);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    if (oldWidget != this) {
      widget.requestFocus.addListener(onRequestFocus);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.requestFocus.removeListener(onRequestFocus);
    widget.requestFocus.dispose();
    super.dispose();
  }

  /// Subclass can override this method to request focus.
  void onRequestFocus();

  String? onCopy() => null;
}

abstract class GridEditableTextCell<T extends EditableCellWidget>
    extends GridCellState<T> {
  SingleListenerFocusNode get focusNode;

  @override
  void initState() {
    super.initState();
    widget.shortcutHandlers[CellKeyboardKey.onEnter] =
        () => focusNode.unfocus();
    _listenOnFocusNodeChanged();
  }

  @override
  void dispose() {
    widget.shortcutHandlers.clear();
    focusNode.removeAllListener();
    focusNode.dispose();
    super.dispose();
  }

  @override
  void onRequestFocus() {
    if (!focusNode.hasFocus && focusNode.canRequestFocus) {
      FocusScope.of(context).requestFocus(focusNode);
    }
  }

  void _listenOnFocusNodeChanged() {
    widget.cellContainerNotifier.isFocus = focusNode.hasFocus;
    focusNode.setListener(() {
      widget.cellContainerNotifier.isFocus = focusNode.hasFocus;
      focusChanged();
    });
  }

  Future<void> focusChanged() async {}
}

class SingleListenerChangeNotifier extends ChangeNotifier {
  VoidCallback? _listener;

  @override
  void addListener(VoidCallback listener) {
    if (_listener != null) {
      removeListener(_listener!);
    }
    _listener = listener;
    super.addListener(listener);
  }

  @override
  void dispose() {
    _listener = null;
    super.dispose();
  }

  void notify() => notifyListeners();
}

class SingleListenerFocusNode extends FocusNode {
  VoidCallback? _listener;

  void setListener(VoidCallback listener) {
    if (_listener != null) {
      removeListener(_listener!);
    }

    _listener = listener;
    super.addListener(listener);
  }

  void removeAllListener() {
    if (_listener != null) {
      removeListener(_listener!);
    }
  }
}

class EditableCellSkinMap {
  EditableCellSkinMap({
    this.checkboxSkin,
    this.checklistSkin,
    this.timestampSkin,
    this.dateSkin,
    this.selectOptionSkin,
    this.numberSkin,
    this.textSkin,
    this.urlSkin,
    this.relationSkin,
  });

  final IEditableCheckboxCellSkin? checkboxSkin;
  final IEditableChecklistCellSkin? checklistSkin;
  final IEditableTimestampCellSkin? timestampSkin;
  final IEditableDateCellSkin? dateSkin;
  final IEditableSelectOptionCellSkin? selectOptionSkin;
  final IEditableNumberCellSkin? numberSkin;
  final IEditableTextCellSkin? textSkin;
  final IEditableURLCellSkin? urlSkin;
  final IEditableRelationCellSkin? relationSkin;

  bool has(FieldType fieldType) {
    return switch (fieldType) {
      FieldType.Checkbox => checkboxSkin != null,
      FieldType.Checklist => checklistSkin != null,
      FieldType.CreatedTime ||
      FieldType.LastEditedTime =>
        timestampSkin != null,
      FieldType.DateTime => dateSkin != null,
      FieldType.MultiSelect ||
      FieldType.SingleSelect =>
        selectOptionSkin != null,
      FieldType.Number => numberSkin != null,
      FieldType.RichText => textSkin != null,
      FieldType.URL => urlSkin != null,
      _ => throw UnimplementedError(),
    };
  }
}

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'editable_cell_skeleton/checkbox.dart';
import 'editable_cell_skeleton/checklist.dart';
import 'editable_cell_skeleton/date.dart';
import 'editable_cell_skeleton/number.dart';
import 'editable_cell_skeleton/select_option.dart';
import 'editable_cell_skeleton/text.dart';
import 'editable_cell_skeleton/timestamp.dart';
import 'editable_cell_skeleton/url.dart';
import '../row/accessory/cell_accessory.dart';
import '../row/accessory/cell_shortcuts.dart';
import '../row/cells/cell_container.dart';

enum EditableCellStyle {
  desktopGrid,
  desktopRowDetail,
  mobileGrid,
  mobileRowDetail,
}

/// Build an editable cell widget
class EditableCellBuilder {
  final DatabaseController databaseController;

  EditableCellBuilder({
    required this.databaseController,
  });

  EditableCellWidget buildStyled(
    CellContext cellContext,
    EditableCellStyle style,
  ) {
    final cellController = makeCellController(databaseController, cellContext);
    final key = ValueKey(
      "${databaseController.viewId}${cellContext.fieldId}${cellContext.rowId}",
    );
    return switch (cellController.fieldType) {
      FieldType.Checkbox => EditableCheckboxCell(
          cellController: cellController.as(),
          skin: IEditableCheckboxCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.Checklist => EditableChecklistCell(
          cellController: cellController.as(),
          skin: IEditableChecklistCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.LastEditedTime ||
      FieldType.CreatedTime =>
        EditableTimestampCell(
          cellController: cellController.as(),
          skin: IEditableTimestampCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.DateTime => EditableDateCell(
          cellController: cellController.as(),
          skin: IEditableDateCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.MultiSelect ||
      FieldType.SingleSelect =>
        EditableSelectOptionCell(
          cellController: cellController.as(),
          skin: IEditableSelectOptionCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.Number => EditableNumberCell(
          cellController: cellController.as(),
          skin: IEditableNumberCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.RichText => EditableTextCell(
          cellController: cellController.as(),
          skin: IEditableTextCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.URL => EditableURLCell(
          cellController: cellController.as(),
          skin: IEditableURLCellSkin.fromStyle(style),
          key: key,
        ),
      _ => throw UnimplementedError(),
    };
  }

  EditableCellWidget buildCustom(
    CellContext cellContext, {
    required EditableCellSkinMap skinMap,
  }) {
    final cellController = makeCellController(databaseController, cellContext);
    final key = ValueKey(
      "${databaseController.viewId}${cellContext.fieldId}${cellContext.rowId}",
    );
    final fieldType = cellController.fieldType;
    assert(skinMap.has(fieldType));
    return switch (fieldType) {
      FieldType.Checkbox => EditableCheckboxCell(
          cellController: cellController.as(),
          skin: skinMap.checkboxSkin!,
          key: key,
        ),
      FieldType.Checklist => EditableChecklistCell(
          cellController: cellController.as(),
          skin: skinMap.checklistSkin!,
          key: key,
        ),
      FieldType.LastEditedTime ||
      FieldType.CreatedTime =>
        EditableTimestampCell(
          cellController: cellController.as(),
          skin: skinMap.timestampSkin!,
          key: key,
        ),
      FieldType.DateTime => EditableDateCell(
          cellController: cellController.as(),
          skin: skinMap.dateSkin!,
          key: key,
        ),
      FieldType.MultiSelect ||
      FieldType.SingleSelect =>
        EditableSelectOptionCell(
          cellController: cellController.as(),
          skin: skinMap.selectOptionSkin!,
          key: key,
        ),
      FieldType.Number => EditableNumberCell(
          cellController: cellController.as(),
          skin: skinMap.numberSkin!,
          key: key,
        ),
      FieldType.RichText => EditableTextCell(
          cellController: cellController.as(),
          skin: skinMap.textSkin!,
          key: key,
        ),
      FieldType.URL => EditableURLCell(
          cellController: cellController.as(),
          skin: skinMap.urlSkin!,
          key: key,
        ),
      _ => throw UnimplementedError(),
    };
  }
}

abstract class CellEditable {
  RequestFocusListener get requestFocus;

  CellContainerNotifier get cellContainerNotifier;

  // ValueNotifier<bool> get onCellEditing;
}

typedef AccessoryBuilder = List<GridCellAccessoryBuilder> Function(
  GridCellAccessoryBuildContext buildContext,
);

abstract class CellAccessory extends Widget {
  const CellAccessory({super.key});

  // The hover will show if the isHover's value is true
  ValueNotifier<bool>? get onAccessoryHover;

  AccessoryBuilder? get accessoryBuilder;
}

abstract class EditableCellWidget extends StatefulWidget
    implements CellAccessory, CellEditable, CellShortcuts {
  EditableCellWidget({super.key});

  @override
  final CellContainerNotifier cellContainerNotifier = CellContainerNotifier();

  // When the cell is focused, we assume that the accessory also be hovered.
  @override
  ValueNotifier<bool> get onAccessoryHover => ValueNotifier(false);

  // @override
  // final ValueNotifier<bool> onCellEditing = ValueNotifier<bool>(false);

  @override
  List<GridCellAccessoryBuilder> Function(
    GridCellAccessoryBuildContext buildContext,
  )? get accessoryBuilder => null;

  @override
  final RequestFocusListener requestFocus = RequestFocusListener();

  @override
  final Map<CellKeyboardKey, CellKeyboardAction> shortcutHandlers = {};
}

abstract class GridCellState<T extends EditableCellWidget> extends State<T> {
  @override
  void initState() {
    super.initState();

    widget.requestFocus.setListener(requestBeginFocus);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    if (oldWidget != this) {
      widget.requestFocus.setListener(requestBeginFocus);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.onAccessoryHover.dispose();
    widget.requestFocus.removeAllListener();
    widget.requestFocus.dispose();
    super.dispose();
  }

  /// Subclass can override this method to request focus.
  void requestBeginFocus();

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
  void requestBeginFocus() {
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

class RequestFocusListener extends ChangeNotifier {
  VoidCallback? _listener;

  void setListener(VoidCallback listener) {
    if (_listener != null) {
      removeListener(_listener!);
    }

    _listener = listener;
    addListener(listener);
  }

  void removeAllListener() {
    if (_listener != null) {
      removeListener(_listener!);
      _listener = null;
    }
  }

  void notify() {
    notifyListeners();
  }
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
  });

  final IEditableCheckboxCellSkin? checkboxSkin;
  final IEditableChecklistCellSkin? checklistSkin;
  final IEditableTimestampCellSkin? timestampSkin;
  final IEditableDateCellSkin? dateSkin;
  final IEditableSelectOptionCellSkin? selectOptionSkin;
  final IEditableNumberCellSkin? numberSkin;
  final IEditableTextCellSkin? textSkin;
  final IEditableURLCellSkin? urlSkin;

  bool has(FieldType fieldType) {
    return switch (fieldType) {
      FieldType.Checkbox => checkboxSkin != null,
      FieldType.Checklist => checklistSkin != null,
      FieldType.CreatedTime ||
      FieldType.LastEditedTime =>
        throw timestampSkin != null,
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

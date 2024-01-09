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

  EditableCellWidget build(CellContext cellContext, EditableCellStyle style) {
    final fieldType = databaseController.fieldController
        .getField(cellContext.fieldId)!
        .fieldType;
    final cellController =
        makeCellController(databaseController, cellContext, fieldType);
    final key = ValueKey(
      "${databaseController.viewId}${cellContext.fieldId}${cellContext.rowId}",
    );
    return switch (fieldType) {
      FieldType.Checkbox => EditableCheckboxCell(
          cellController: cellController.as(),
          skin: IEditableCheckboxSkin.fromStyle(style),
          key: key,
        ),
      FieldType.Checklist => EditableChecklistCell(
          cellController: cellController.as(),
          skin: IEditableChecklistSkin.fromStyle(style),
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
          builder: IEditableSelectOptionCellSkin.fromStyle(style),
          key: key,
        ),
      FieldType.Number => EditableNumberCell(
          cellController: cellController.as(),
          builder: IEditableNumberCellSkin.fromStyle(style),
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
}

class BlankCell extends StatelessWidget {
  const BlankCell({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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

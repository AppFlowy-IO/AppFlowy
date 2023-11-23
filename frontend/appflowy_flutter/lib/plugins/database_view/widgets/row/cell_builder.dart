import 'package:appflowy/mobile/presentation/database/card/row/cells/cells.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../application/cell/cell_service.dart';
import 'accessory/cell_accessory.dart';
import 'accessory/cell_shortcuts.dart';
import 'cells/cell_container.dart';
import 'cells/checkbox_cell/checkbox_cell.dart';
import 'cells/checklist_cell/checklist_cell.dart';
import 'cells/date_cell/date_cell.dart';
import 'cells/number_cell/number_cell.dart';
import 'cells/select_option_cell/select_option_cell.dart';
import 'cells/text_cell/text_cell.dart';
import 'cells/timestamp_cell/timestamp_cell.dart';
import 'cells/url_cell/url_cell.dart';

/// Build the cell widget in Grid style.
class GridCellBuilder {
  final CellMemCache cellCache;
  GridCellBuilder({
    required this.cellCache,
  });

  GridCellWidget build(
    DatabaseCellContext cellContext, {
    GridCellStyle? style,
  }) {
    final cellControllerBuilder = CellControllerBuilder(
      cellContext: cellContext,
      cellCache: cellCache,
    );

    final key = cellContext.key();

    if (PlatformExtension.isMobile) {
      return _getMobileCardCellWidget(
        key,
        cellContext,
        cellControllerBuilder,
        style,
      );
    }

    return _getDesktopGridCellWidget(
      key,
      cellContext,
      cellControllerBuilder,
      style,
    );
  }

  GridCellWidget _getDesktopGridCellWidget(
    ValueKey key,
    DatabaseCellContext cellContext,
    CellControllerBuilder cellControllerBuilder,
    GridCellStyle? style,
  ) {
    switch (cellContext.fieldType) {
      case FieldType.Checkbox:
        return GridCheckboxCell(
          cellControllerBuilder: cellControllerBuilder,
          style: style,
          key: key,
        );
      case FieldType.DateTime:
        return GridDateCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
          style: style,
        );
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return GridTimestampCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
          style: style,
          fieldType: cellContext.fieldType,
        );
      case FieldType.SingleSelect:
        return GridSingleSelectCell(
          cellControllerBuilder: cellControllerBuilder,
          style: style,
          key: key,
        );
      case FieldType.MultiSelect:
        return GridMultiSelectCell(
          cellControllerBuilder: cellControllerBuilder,
          style: style,
          key: key,
        );
      case FieldType.Checklist:
        return GridChecklistCell(
          cellControllerBuilder: cellControllerBuilder,
          style: style,
          key: key,
        );
      case FieldType.Number:
        return GridNumberCell(
          cellControllerBuilder: cellControllerBuilder,
          style: style,
          key: key,
        );
      case FieldType.RichText:
        return GridTextCell(
          cellControllerBuilder: cellControllerBuilder,
          style: style,
          key: key,
        );
      case FieldType.URL:
        return GridURLCell(
          cellControllerBuilder: cellControllerBuilder,
          style: style,
          key: key,
        );
    }

    throw UnimplementedError;
  }
}

// editable cell/(card's propery value) widget
GridCellWidget _getMobileCardCellWidget(
  ValueKey key,
  DatabaseCellContext cellContext,
  CellControllerBuilder cellControllerBuilder,
  GridCellStyle? style,
) {
  switch (cellContext.fieldType) {
    case FieldType.RichText:
      style as GridTextCellStyle?;
      return MobileTextCell(
        cellControllerBuilder: cellControllerBuilder,
        hintText: style?.placeholder,
      );
    case FieldType.Number:
      style as GridNumberCellStyle?;
      return MobileNumberCell(
        cellControllerBuilder: cellControllerBuilder,
        hintText: style?.placeholder,
      );
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return MobileTimestampCell(
        cellControllerBuilder: cellControllerBuilder,
        key: key,
      );
    case FieldType.Checkbox:
      return MobileCheckboxCell(
        cellControllerBuilder: cellControllerBuilder,
        key: key,
      );
    case FieldType.DateTime:
      style as DateCellStyle?;
      return MobileDateCell(
        cellControllerBuilder: cellControllerBuilder,
        hintText: style?.placeholder,
        key: key,
      );
    case FieldType.URL:
      style as GridURLCellStyle?;
      return MobileURLCell(
        cellControllerBuilder: cellControllerBuilder,
        hintText: style?.placeholder,
        key: key,
      );
    // TODO(yijing):  implement the following mobile select option cell
    case FieldType.SingleSelect:
      return GridSingleSelectCell(
        cellControllerBuilder: cellControllerBuilder,
        style: style,
        key: key,
      );
    case FieldType.MultiSelect:
      return GridMultiSelectCell(
        cellControllerBuilder: cellControllerBuilder,
        style: style,
        key: key,
      );
    case FieldType.Checklist:
      return GridChecklistCell(
        cellControllerBuilder: cellControllerBuilder,
        style: style,
        key: key,
      );
  }
  throw UnimplementedError;
}

class BlankCell extends StatelessWidget {
  const BlankCell({Key? key}) : super(key: key);

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
  const CellAccessory({Key? key}) : super(key: key);

  // The hover will show if the isHover's value is true
  ValueNotifier<bool>? get onAccessoryHover;

  AccessoryBuilder? get accessoryBuilder;
}

abstract class GridCellWidget extends StatefulWidget
    implements CellAccessory, CellEditable, CellShortcuts {
  GridCellWidget({super.key});

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

abstract class GridCellState<T extends GridCellWidget> extends State<T> {
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

abstract class GridEditableTextCell<T extends GridCellWidget>
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
  void didUpdateWidget(covariant T oldWidget) {
    // if (!focusNode.hasFocus && widget.cellContainerNotifier.isFocus) {
    //   focusNode.requestFocus();
    // } else if (focusNode.hasFocus && !widget.cellContainerNotifier.isFocus) {
    //   focusNode.unfocus();
    // }
    super.didUpdateWidget(oldWidget);
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

abstract class GridCellStyle {
  const GridCellStyle();
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

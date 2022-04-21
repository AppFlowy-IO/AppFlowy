import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show FieldType;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'checkbox_cell.dart';
import 'date_cell.dart';
import 'number_cell.dart';
import 'selection_cell/selection_cell.dart';
import 'text_cell.dart';

GridCellWidget buildGridCell(GridCell cellData, {GridCellStyle? style}) {
  final key = ValueKey(cellData.field.id + cellData.rowId);
  switch (cellData.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxCell(cellData: cellData, key: key);
    case FieldType.DateTime:
      return DateCell(cellData: cellData, key: key);
    case FieldType.MultiSelect:
      return MultiSelectCell(cellData: cellData, key: key);
    case FieldType.Number:
      return NumberCell(cellData: cellData, key: key);
    case FieldType.RichText:
      return GridTextCell(cellData: cellData, key: key, style: style);
    case FieldType.SingleSelect:
      return SingleSelectCell(cellData: cellData, key: key);
    default:
      throw UnimplementedError;
  }
}

class BlankCell extends StatelessWidget {
  const BlankCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

abstract class GridCellWidget extends HoverWidget {
  @override
  final ValueNotifier<bool> onFocus = ValueNotifier<bool>(false);
  GridCellWidget({Key? key}) : super(key: key);
}

abstract class B {
  ValueNotifier<bool> get onFocus;
}

abstract class GridCellStyle {}

//
abstract class HoverWidget extends StatefulWidget {
  const HoverWidget({Key? key}) : super(key: key);

  ValueNotifier<bool> get onFocus;
}

class FlowyHover2 extends StatefulWidget {
  final HoverWidget child;
  const FlowyHover2({required this.child, Key? key}) : super(key: key);

  @override
  State<FlowyHover2> createState() => _FlowyHover2State();
}

class _FlowyHover2State extends State<FlowyHover2> {
  late FlowyHoverState _hoverState;

  @override
  void initState() {
    _hoverState = FlowyHoverState();
    widget.child.onFocus.addListener(() {
      _hoverState.onFocus = widget.child.onFocus.value;
    });
    super.initState();
  }

  @override
  void dispose() {
    _hoverState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _hoverState,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        opaque: false,
        onEnter: (p) => setState(() => _hoverState.onHover = true),
        onExit: (p) => setState(() => _hoverState.onHover = false),
        child: Stack(
          fit: StackFit.expand,
          alignment: AlignmentDirectional.center,
          children: [
            const _HoverBackground(),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _HoverBackground extends StatelessWidget {
  const _HoverBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Consumer<FlowyHoverState>(
      builder: (context, state, child) {
        if (state.onHover || state.onFocus) {
          return FlowyHoverContainer(
            style: HoverStyle(
              borderRadius: Corners.s6Border,
              hoverColor: theme.shader6,
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}

class FlowyHoverState extends ChangeNotifier {
  bool _onHover = false;
  bool _onFocus = false;

  set onHover(bool value) {
    if (_onHover != value) {
      _onHover = value;
      notifyListeners();
    }
  }

  bool get onHover => _onHover;

  set onFocus(bool value) {
    if (_onFocus != value) {
      _onFocus = value;
      notifyListeners();
    }
  }

  bool get onFocus => _onFocus;
}

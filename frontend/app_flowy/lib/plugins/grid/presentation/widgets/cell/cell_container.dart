import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../layout/sizes.dart';
import '../row/grid_row.dart';
import 'cell_accessory.dart';
import 'cell_builder.dart';
import 'cell_shortcuts.dart';

class CellContainer extends StatelessWidget {
  final GridCellWidget child;
  final AccessoryBuilder? accessoryBuilder;
  final double width;
  final bool isPrimary;
  const CellContainer({
    Key? key,
    required this.child,
    required this.width,
    required this.isPrimary,
    this.accessoryBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_CellContainerNotifier>(
      create: (_) => _CellContainerNotifier(child),
      child: Selector<_CellContainerNotifier, bool>(
        selector: (context, notifier) => notifier.isFocus,
        builder: (privderContext, isFocus, _) {
          Widget container = Center(child: GridCellShortcuts(child: child));

          if (accessoryBuilder != null) {
            final accessories = accessoryBuilder!(
              GridCellAccessoryBuildContext(
                anchorContext: context,
                isCellEditing: isFocus,
              ),
            );

            if (accessories.isNotEmpty) {
              container = _GridCellEnterRegion(
                accessories: accessories,
                isPrimary: isPrimary,
                child: container,
              );
            }
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => child.beginFocus.notify(),
            child: Container(
              constraints: BoxConstraints(maxWidth: width, minHeight: 46),
              decoration: _makeBoxDecoration(context, isFocus),
              child: container,
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context, bool isFocus) {
    if (isFocus) {
      final borderSide = BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.0,
      );
      return BoxDecoration(border: Border.fromBorderSide(borderSide));
    } else {
      final borderSide = BorderSide(
        color: Theme.of(context).dividerColor,
        width: 1.0,
      );
      return BoxDecoration(
          border: Border(right: borderSide, bottom: borderSide));
    }
  }
}

class _GridCellEnterRegion extends StatelessWidget {
  final Widget child;
  final List<GridCellAccessoryBuilder> accessories;
  final bool isPrimary;
  const _GridCellEnterRegion({
    required this.child,
    required this.accessories,
    required this.isPrimary,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector2<RegionStateNotifier, _CellContainerNotifier, bool>(
      selector: (context, regionNotifier, cellNotifier) =>
          !cellNotifier.isFocus &&
          (cellNotifier.onEnter || regionNotifier.onEnter && isPrimary),
      builder: (context, showAccessory, _) {
        List<Widget> children = [child];
        if (showAccessory) {
          children.add(
            CellAccessoryContainer(accessories: accessories).positioned(
              right: GridSize.cellContentInsets.right,
            ),
          );
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (p) =>
              Provider.of<_CellContainerNotifier>(context, listen: false)
                  .onEnter = true,
          onExit: (p) =>
              Provider.of<_CellContainerNotifier>(context, listen: false)
                  .onEnter = false,
          child: Stack(
            alignment: AlignmentDirectional.center,
            fit: StackFit.expand,
            children: children,
          ),
        );
      },
    );
  }
}

class _CellContainerNotifier extends ChangeNotifier {
  final CellEditable cellEditable;
  VoidCallback? _onCellFocusListener;
  bool _isFocus = false;
  bool _onEnter = false;

  _CellContainerNotifier(this.cellEditable) {
    _onCellFocusListener = () => isFocus = cellEditable.onCellFocus.value;
    cellEditable.onCellFocus.addListener(_onCellFocusListener!);
  }

  @override
  void dispose() {
    if (_onCellFocusListener != null) {
      cellEditable.onCellFocus.removeListener(_onCellFocusListener!);
    }
    super.dispose();
  }

  set isFocus(bool value) {
    if (_isFocus != value) {
      _isFocus = value;
      notifyListeners();
    }
  }

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get isFocus => _isFocus;

  bool get onEnter => _onEnter;
}

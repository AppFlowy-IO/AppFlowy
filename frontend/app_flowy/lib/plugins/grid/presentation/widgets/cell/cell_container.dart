import 'package:flowy_infra/theme.dart';
import 'package:flutter/widgets.dart';
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
  final RegionStateNotifier rowStateNotifier;
  const CellContainer({
    Key? key,
    required this.child,
    required this.width,
    required this.rowStateNotifier,
    this.accessoryBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<RegionStateNotifier,
        _CellContainerNotifier>(
      create: (_) => _CellContainerNotifier(child),
      update: (_, rowStateNotifier, cellStateNotifier) =>
          cellStateNotifier!..onEnter = rowStateNotifier.onEnter,
      child: Selector<_CellContainerNotifier, bool>(
        selector: (context, notifier) => notifier.isFocus,
        builder: (context, isFocus, _) {
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
              padding: GridSize.cellContentInsets,
              child: container,
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context, bool isFocus) {
    final theme = context.watch<AppTheme>();
    if (isFocus) {
      final borderSide = BorderSide(color: theme.main1, width: 1.0);
      return BoxDecoration(border: Border.fromBorderSide(borderSide));
    } else {
      final borderSide = BorderSide(color: theme.shader5, width: 1.0);
      return BoxDecoration(
          border: Border(right: borderSide, bottom: borderSide));
    }
  }
}

class _GridCellEnterRegion extends StatelessWidget {
  final Widget child;
  final List<GridCellAccessoryBuilder> accessories;
  const _GridCellEnterRegion(
      {required this.child, required this.accessories, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<_CellContainerNotifier, bool>(
      selector: (context, notifier) => notifier.onEnter,
      builder: (context, onEnter, _) {
        List<Widget> children = [child];
        if (onEnter) {
          children.add(CellAccessoryContainer(accessories: accessories)
              .positioned(right: 0));
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

import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/row/grid_row.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'cell_builder.dart';

class CellStateNotifier extends ChangeNotifier {
  bool _isFocus = false;
  bool _onEnter = false;

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

class CellContainer extends StatelessWidget {
  final GridCellWidget child;
  final Widget? expander;
  final double width;
  final RegionStateNotifier rowStateNotifier;
  const CellContainer({
    Key? key,
    required this.child,
    required this.width,
    required this.rowStateNotifier,
    this.expander,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<RegionStateNotifier, CellStateNotifier>(
      create: (_) => CellStateNotifier(),
      update: (_, row, cell) => cell!..onEnter = row.onEnter,
      child: Selector<CellStateNotifier, bool>(
        selector: (context, notifier) => notifier.isFocus,
        builder: (context, isFocus, _) {
          Widget container = Center(child: child);
          child.onFocus.addListener(() {
            Provider.of<CellStateNotifier>(context, listen: false).isFocus = child.onFocus.value;
          });

          if (expander != null) {
            container = _CellEnterRegion(child: container, expander: expander!);
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => child.requestFocus.notify(),
            child: Container(
              constraints: BoxConstraints(maxWidth: width),
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
      final borderSide = BorderSide(color: theme.shader4, width: 0.4);
      return BoxDecoration(border: Border(right: borderSide, bottom: borderSide));
    }
  }
}

class _CellEnterRegion extends StatelessWidget {
  final Widget child;
  final Widget expander;
  const _CellEnterRegion({required this.child, required this.expander, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<CellStateNotifier, bool>(
      selector: (context, notifier) => notifier.onEnter,
      builder: (context, onEnter, _) {
        List<Widget> children = [Expanded(child: child)];
        if (onEnter) {
          children.add(expander);
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (p) => Provider.of<CellStateNotifier>(context, listen: false).onEnter = true,
          onExit: (p) => Provider.of<CellStateNotifier>(context, listen: false).onEnter = false,
          child: Row(
            // alignment: AlignmentDirectional.centerEnd,
            children: children,
          ),
        );
      },
    );
  }
}

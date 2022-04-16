import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';

class CellStateNotifier extends ChangeNotifier {
  bool _isFocus = false;

  set isFocus(bool value) {
    if (_isFocus != value) {
      _isFocus = value;
      notifyListeners();
    }
  }

  bool get isFocus => _isFocus;
}

class CellContainer extends StatelessWidget {
  final Widget child;
  final double width;
  const CellContainer({
    Key? key,
    required this.child,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CellStateNotifier(),
      child: Consumer<CellStateNotifier>(
        builder: (context, state, _) {
          return Container(
            constraints: BoxConstraints(maxWidth: width),
            decoration: _makeBoxDecoration(context, state),
            padding: GridSize.cellContentInsets,
            child: Center(child: child),
          );
        },
      ),
    );
  }

  BoxDecoration _makeBoxDecoration(BuildContext context, CellStateNotifier state) {
    final theme = context.watch<AppTheme>();
    if (state.isFocus) {
      final borderSide = BorderSide(color: theme.main1, width: 1.0);
      return BoxDecoration(border: Border.fromBorderSide(borderSide));
    } else {
      final borderSide = BorderSide(color: theme.shader4, width: 0.4);
      return BoxDecoration(border: Border(right: borderSide, bottom: borderSide));
    }
  }
}

abstract class GridCell extends StatefulWidget {
  const GridCell({Key? key}) : super(key: key);

  void setFocus(BuildContext context, bool value) {
    Provider.of<CellStateNotifier>(context, listen: false).isFocus = value;
  }
}

class CellFocusNode extends FocusNode {
  VoidCallback? focusCallback;

  void addCallback(BuildContext context, VoidCallback callback) {
    if (focusCallback != null) {
      removeListener(focusCallback!);
    }
    focusCallback = () {
      Provider.of<CellStateNotifier>(context, listen: false).isFocus = hasFocus;
      callback();
    };

    addListener(focusCallback!);
  }

  @override
  void dispose() {
    if (focusCallback != null) {
      removeListener(focusCallback!);
    }
    super.dispose();
  }
}

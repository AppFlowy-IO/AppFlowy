import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CellKeyboardAction = VoidCallback;

enum CellKeyboardKey {
  onEnter,
}

abstract class CellShortcuts extends Widget {
  const CellShortcuts({Key? key}) : super(key: key);

  Map<CellKeyboardKey, CellKeyboardAction> get keyboardActionHandlers;
}

class GridCellShortcuts extends StatelessWidget {
  final CellShortcuts child;
  const GridCellShortcuts({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {LogicalKeySet(LogicalKeyboardKey.enter): const GridCellEnterIdent()},
      child: Actions(
        actions: {GridCellEnterIdent: GridCellEnterAction(child: child)},
        child: child,
      ),
    );
  }
}

class GridCellEnterIdent extends Intent {
  const GridCellEnterIdent();
}

class GridCellEnterAction extends Action<GridCellEnterIdent> {
  final CellShortcuts child;
  GridCellEnterAction({required this.child});

  @override
  void invoke(covariant GridCellEnterIdent intent) {
    final callback = child.keyboardActionHandlers[CellKeyboardKey.onEnter];
    if (callback != null) {
      callback();
    }
  }
}

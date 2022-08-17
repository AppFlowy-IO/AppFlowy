import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CellKeyboardAction = dynamic Function();

enum CellKeyboardKey {
  onEnter,
  onCopy,
  onInsert,
}

abstract class CellShortcuts extends Widget {
  const CellShortcuts({Key? key}) : super(key: key);

  Map<CellKeyboardKey, CellKeyboardAction> get shortcutHandlers;
}

class GridCellShortcuts extends StatelessWidget {
  final CellShortcuts child;
  const GridCellShortcuts({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): const GridCellEnterIdent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
            const GridCellCopyIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
            const GridCellPasteIntent(),
      },
      child: Actions(
        actions: {
          GridCellEnterIdent: GridCellEnterAction(child: child),
          GridCellCopyIntent: GridCellCopyAction(child: child),
          GridCellPasteIntent: GridCellPasteAction(child: child),
        },
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
    final callback = child.shortcutHandlers[CellKeyboardKey.onEnter];
    if (callback != null) {
      callback();
    }
  }
}

class GridCellCopyIntent extends Intent {
  const GridCellCopyIntent();
}

class GridCellCopyAction extends Action<GridCellCopyIntent> {
  final CellShortcuts child;
  GridCellCopyAction({required this.child});

  @override
  void invoke(covariant GridCellCopyIntent intent) {
    final callback = child.shortcutHandlers[CellKeyboardKey.onCopy];
    if (callback == null) {
      return;
    }

    final s = callback();
    if (s is String) {
      Clipboard.setData(ClipboardData(text: s));
    }
  }
}

class GridCellPasteIntent extends Intent {
  const GridCellPasteIntent();
}

class GridCellPasteAction extends Action<GridCellPasteIntent> {
  final CellShortcuts child;
  GridCellPasteAction({required this.child});

  @override
  void invoke(covariant GridCellPasteIntent intent) {
    final callback = child.shortcutHandlers[CellKeyboardKey.onInsert];
    if (callback != null) {
      callback();
    }
  }
}

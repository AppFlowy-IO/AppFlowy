import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CellKeyboardAction = dynamic Function();

enum CellKeyboardKey {
  onEnter,
  onCopy,
  onCut,
  onPaste,
  onDelete,
  onInsert,
}

abstract class CellShortcuts extends Widget {
  const CellShortcuts({super.key});

  Map<CellKeyboardKey, CellKeyboardAction> get shortcutHandlers;
}

class GridCellShortcuts extends StatelessWidget {
  const GridCellShortcuts({required this.child, super.key});

  final CellShortcuts child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: child,
      ),
    );
  }

  Map<ShortcutActivator, Intent> get shortcuts => {
        if (shouldAddKeyboardKey(CellKeyboardKey.onEnter))
          LogicalKeySet(LogicalKeyboardKey.enter): const GridCellEnterIdent(),
        if (shouldAddKeyboardKey(CellKeyboardKey.onCopy))
          LogicalKeySet(
            Platform.isMacOS
                ? LogicalKeyboardKey.meta
                : LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyC,
          ): const GridCellCopyIntent(),
        if (shouldAddKeyboardKey(CellKeyboardKey.onCut))
          LogicalKeySet(
            Platform.isMacOS
                ? LogicalKeyboardKey.meta
                : LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyX,
          ): const GridCellCutIntent(),
        if (shouldAddKeyboardKey(CellKeyboardKey.onPaste))
          LogicalKeySet(
            Platform.isMacOS
                ? LogicalKeyboardKey.meta
                : LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyV,
          ): const GridCellPasteIntent(),
        if (shouldAddKeyboardKey(CellKeyboardKey.onDelete))
          LogicalKeySet(LogicalKeyboardKey.delete): const GridCellDeleteIntent(),
        if (shouldAddKeyboardKey(CellKeyboardKey.onDelete))
          LogicalKeySet(LogicalKeyboardKey.backspace): const GridCellDeleteIntent(),
      };

  Map<Type, Action<Intent>> get actions => {
        if (shouldAddKeyboardKey(CellKeyboardKey.onEnter))
          GridCellEnterIdent: GridCellEnterAction(child: child),
        if (shouldAddKeyboardKey(CellKeyboardKey.onCopy))
          GridCellCopyIntent: GridCellCopyAction(child: child),
        if (shouldAddKeyboardKey(CellKeyboardKey.onCut))
          GridCellCutIntent: GridCellCutAction(child: child),
        if (shouldAddKeyboardKey(CellKeyboardKey.onPaste))
          GridCellPasteIntent: GridCellPasteAction(child: child),
        if (shouldAddKeyboardKey(CellKeyboardKey.onDelete))
          GridCellDeleteIntent: GridCellDeleteAction(child: child),
      };

  bool shouldAddKeyboardKey(CellKeyboardKey key) =>
      child.shortcutHandlers.containsKey(key);
}

class GridCellEnterIdent extends Intent {
  const GridCellEnterIdent();
}

class GridCellEnterAction extends Action<GridCellEnterIdent> {
  GridCellEnterAction({required this.child});

  final CellShortcuts child;

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
  GridCellCopyAction({required this.child});

  final CellShortcuts child;

  @override
  void invoke(covariant GridCellCopyIntent intent) {
    final callback = child.shortcutHandlers[CellKeyboardKey.onCopy];
    if (callback != null) callback();
  }
}

class GridCellCutIntent extends Intent {
  const GridCellCutIntent();
}

class GridCellCutAction extends Action<GridCellCutIntent> {
  GridCellCutAction({required this.child});

  final CellShortcuts child;

  @override
  void invoke(covariant GridCellCutIntent intent) {
    final callback = child.shortcutHandlers[CellKeyboardKey.onCut];
    if (callback != null) callback();
  }
}

class GridCellPasteIntent extends Intent {
  const GridCellPasteIntent();
}

class GridCellPasteAction extends Action<GridCellPasteIntent> {
  GridCellPasteAction({required this.child});

  final CellShortcuts child;

  @override
  Future<void> invoke(covariant GridCellPasteIntent intent) async {
    final callback = child.shortcutHandlers[CellKeyboardKey.onPaste];
    if (callback != null) await callback();
  }
}

class GridCellDeleteIntent extends Intent {
  const GridCellDeleteIntent();
}

class GridCellDeleteAction extends Action<GridCellDeleteIntent> {
  GridCellDeleteAction({required this.child});

  final CellShortcuts child;

  @override
  void invoke(covariant GridCellDeleteIntent intent) {
    final callback = child.shortcutHandlers[CellKeyboardKey.onDelete];
    if (callback != null) callback();
  }
}

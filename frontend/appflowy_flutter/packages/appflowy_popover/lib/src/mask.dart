import 'dart:collection';

import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';

typedef _EntryMap = LinkedHashMap<PopoverState, OverlayEntryContext>;

class RootOverlayEntry {
  final _EntryMap _entries = _EntryMap();

  bool contains(PopoverState state) => _entries.containsKey(state);

  bool get isEmpty => _entries.isEmpty;
  bool get isNotEmpty => _entries.isNotEmpty;

  void addEntry(
    BuildContext context,
    String id,
    PopoverState newState,
    OverlayEntry entry,
    bool asBarrier,
    AnimationController animationController,
  ) {
    _entries[newState] = OverlayEntryContext(
      id,
      entry,
      newState,
      asBarrier,
      animationController,
    );
    Overlay.of(context).insert(entry);
  }

  void removeEntry(PopoverState state) {
    final removedEntry = _entries.remove(state);
    removedEntry?.overlayEntry.remove();
  }

  OverlayEntryContext? popEntry() {
    if (isEmpty) {
      return null;
    }

    final lastEntry = _entries.values.last;
    _entries.remove(lastEntry.popoverState);
    lastEntry.animationController.reverse().then((_) {
      lastEntry.overlayEntry.remove();
      lastEntry.popoverState.widget.onClose?.call();
    });

    return lastEntry.asBarrier ? lastEntry : popEntry();
  }

  bool isLastEntryAsBarrier() {
    if (isEmpty) {
      return false;
    }

    return _entries.values.last.asBarrier;
  }
}

class OverlayEntryContext {
  OverlayEntryContext(
    this.id,
    this.overlayEntry,
    this.popoverState,
    this.asBarrier,
    this.animationController,
  );

  final String id;
  final OverlayEntry overlayEntry;
  final PopoverState popoverState;
  final bool asBarrier;
  final AnimationController animationController;

  @override
  String toString() {
    return 'OverlayEntryContext(id: $id, asBarrier: $asBarrier, popoverState: ${popoverState.widget.debugId})';
  }
}

class PopoverMask extends StatelessWidget {
  const PopoverMask({
    super.key,
    required this.onTap,
    this.decoration,
  });

  final VoidCallback onTap;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: decoration,
      ),
    );
  }
}

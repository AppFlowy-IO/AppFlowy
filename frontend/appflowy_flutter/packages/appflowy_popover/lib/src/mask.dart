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
    PopoverState newState,
    OverlayEntry entry,
    bool asBarrier,
  ) {
    _entries[newState] = OverlayEntryContext(
      entry,
      newState,
      asBarrier,
    );
    Overlay.of(context).insert(entry);
  }

  void removeEntry(PopoverState state) {
    final removedEntry = _entries.remove(state);
    removedEntry?.overlayEntry.remove();
  }

  PopoverState? popEntry() {
    if (isEmpty) {
      return null;
    }

    final lastEntry = _entries.values.last;
    _entries.remove(lastEntry.popoverState);
    lastEntry.overlayEntry.remove();
    lastEntry.popoverState.widget.onClose?.call();

    return lastEntry.asBarrier ? lastEntry.popoverState : popEntry();
  }
}

class OverlayEntryContext {
  OverlayEntryContext(
    this.overlayEntry,
    this.popoverState,
    this.asBarrier,
  );

  final OverlayEntry overlayEntry;
  final PopoverState popoverState;
  final bool asBarrier;
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

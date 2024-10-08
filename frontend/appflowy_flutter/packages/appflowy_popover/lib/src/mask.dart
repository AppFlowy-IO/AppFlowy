import 'dart:collection';

import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';

typedef EntryMap = LinkedHashMap<PopoverState, OverlayEntryContext>;

class RootOverlayEntry {
  RootOverlayEntry();

  final EntryMap _entries = EntryMap();

  void addEntry(
    BuildContext context,
    PopoverState newState,
    OverlayEntry entry,
    bool asBarrier,
  ) {
    _entries[newState] = OverlayEntryContext(entry, newState, asBarrier);
    Overlay.of(context).insert(entry);
  }

  bool contains(PopoverState oldState) {
    return _entries.containsKey(oldState);
  }

  void removeEntry(PopoverState oldState) {
    if (_entries.isEmpty) return;

    final removedEntry = _entries.remove(oldState);
    removedEntry?.overlayEntry.remove();
  }

  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  bool hasEntry() {
    return _entries.isNotEmpty;
  }

  PopoverState? popEntry() {
    if (_entries.isEmpty) return null;

    final lastEntry = _entries.values.last;
    _entries.remove(lastEntry.popoverState);
    lastEntry.overlayEntry.remove();
    lastEntry.popoverState.widget.onClose?.call();

    if (lastEntry.asBarrier) {
      return lastEntry.popoverState;
    } else {
      return popEntry();
    }
  }
}

class OverlayEntryContext {
  OverlayEntryContext(
    this.overlayEntry,
    this.popoverState,
    this.asBarrier,
  );

  final bool asBarrier;
  final PopoverState popoverState;
  final OverlayEntry overlayEntry;
}

class PopoverMask extends StatelessWidget {
  const PopoverMask({
    super.key,
    required this.onTap,
    this.decoration,
  });

  final void Function() onTap;
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

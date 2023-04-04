import 'dart:collection';

import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef EntryMap = LinkedHashMap<PopoverState, OverlayEntryContext>;

class RootOverlayEntry {
  final EntryMap _entries = EntryMap();
  RootOverlayEntry();

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
  final bool asBarrier;
  final PopoverState popoverState;
  final OverlayEntry overlayEntry;

  OverlayEntryContext(
    this.overlayEntry,
    this.popoverState,
    this.asBarrier,
  );
}

class PopoverMask extends StatefulWidget {
  final void Function() onTap;
  final void Function()? onExit;
  final Decoration? decoration;

  const PopoverMask(
      {Key? key, required this.onTap, this.onExit, this.decoration})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PopoverMaskState();
}

class _PopoverMaskState extends State<PopoverMask> {
  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    super.initState();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent) {
      if (widget.onExit != null) {
        widget.onExit!();
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  void deactivate() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: widget.decoration,
      ),
    );
  }
}

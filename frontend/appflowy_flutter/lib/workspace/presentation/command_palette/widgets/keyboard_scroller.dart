import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardScroller<T> extends StatefulWidget {
  const KeyboardScroller({
    super.key,
    required this.controller,
    required this.list,
    required this.onSelect,
    required this.idGetter,
    required this.selectedIndexGetter,
    required this.builder,
  });

  final ScrollController controller;
  final List<T> list;
  final ValueGetter<int> selectedIndexGetter;
  final ValueChanged<int> onSelect;
  final IdGetter<T> idGetter;
  final KeyboardScrollerBuilder builder;

  @override
  State<KeyboardScroller<T>> createState() => _KeyboardScrollerState<T>();
}

class _KeyboardScrollerState<T> extends State<KeyboardScroller<T>> {
  int get length => widget.list.length;

  final AreaDetectors areaDetector = AreaDetectors();

  @override
  void dispose() {
    areaDetector._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        SingleActivator(LogicalKeyboardKey.arrowUp):
            VoidCallbackIntent(() => _moveSelection(AxisDirection.up, context)),
        SingleActivator(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(
          () => _moveSelection(AxisDirection.down, context),
        ),
      },
      child: widget.builder.call(context, areaDetector),
    );
  }

  bool _moveSelection(AxisDirection direction, BuildContext context) {
    if (length == 0) return false;
    final index = widget.selectedIndexGetter.call();
    int newIndex = index;
    final isUp = direction == AxisDirection.up;
    if (index < 0) {
      newIndex = isUp ? length - 1 : 0;
    } else {
      if (isUp) {
        newIndex = index == 0 ? length - 1 : index - 1;
      } else {
        newIndex = index == length - 1 ? 0 : index + 1;
      }
    }
    widget.onSelect(newIndex);
    _scrollToItem(index, newIndex, context);
    return true;
  }

  void _scrollToItem(
    int from,
    int to,
    BuildContext context,
  ) {
    if (!context.mounted) return;

    /// scroll to the end
    if (to == length - 1) {
      widget.controller.jumpTo(widget.controller.position.maxScrollExtent);
      return;
    } else if (to == 0) {
      /// scroll to the start
      widget.controller.jumpTo(0);
      return;
    }
    final id = widget.idGetter(widget.list[to]);

    final isTopArea = areaDetector.getAreaType(id) == AreaType.top;

    final currentPosition = widget.controller.position.pixels;
    if (isTopArea && from > to) {
      widget.controller.jumpTo(max(0, currentPosition - 50));
    } else if (!isTopArea && from < to) {
      widget.controller.jumpTo(
        min(currentPosition + 50, widget.controller.position.maxScrollExtent),
      );
    }
  }
}

typedef KeyboardScrollerBuilder = Widget Function(
  BuildContext context,
  AreaDetectors detectors,
);

typedef IdGetter<T> = String Function(T t);

enum AreaType { top, bottom }

extension AreaTypeSearchPanelExtension on GlobalKey {
    AreaType? getAreaType(BuildContext context) {
    final renderObject = currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final searchPanelHeight = min(MediaQuery.of(context).size.height - 100, 640);
      final position = renderObject.localToGlobal(Offset.zero);
      if (position.dy < searchPanelHeight / 2) {
        return AreaType.top;
      } else {
        return AreaType.bottom;
      }
    }
    return null;
  }
}

class AreaDetectors {
  final Map<String, Set<ValueGetter<AreaType?>>> _detectors = {};

  void addDetector(String key, ValueGetter<AreaType?> detector) {
    final set = _detectors[key] ?? {};
    set.add(detector);
    _detectors[key] = set;
  }

  void removeDetector(String key, ValueGetter<AreaType?> detector) {
    final set = _detectors[key] ?? {};
    set.remove(detector);
    if (set.isEmpty) {
      _detectors.remove(key);
    } else {
      _detectors[key] = set;
    }
  }

  AreaType? getAreaType(String key) {
    final set = _detectors[key] ?? {};
    if (set.isEmpty) return null;
    return set.first.call();
  }

  void _dispose() {
    _detectors.clear();
  }
}

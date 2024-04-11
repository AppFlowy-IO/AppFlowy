import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PopupMenu extends StatefulWidget {
  const PopupMenu({
    super.key,
    required this.onSelected,
    required this.itemLength,
    required this.menuBuilder,
    required this.builder,
  });

  final Widget Function(BuildContext context, Key key) builder;
  final int itemLength;
  final Widget Function(
    BuildContext context,
    List<GlobalKey> keys,
    int currentIndex,
  ) menuBuilder;
  final void Function(int index) onSelected;

  @override
  State<PopupMenu> createState() => _PopupMenuState();
}

class _PopupMenuState extends State<PopupMenu> {
  final key = GlobalKey();
  final indexNotifier = ValueNotifier(-1);
  late List<GlobalKey> itemKeys;

  OverlayEntry? popupMenuOverlayEntry;

  Rect get rect {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }

  @override
  void initState() {
    super.initState();

    indexNotifier.value = widget.itemLength - 1;
    itemKeys = List.generate(
      widget.itemLength,
      (_) => GlobalKey(),
    );

    indexNotifier.addListener(HapticFeedback.mediumImpact);
  }

  @override
  void dispose() {
    indexNotifier.removeListener(HapticFeedback.mediumImpact);
    indexNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) {
        _showMenu(context);
      },
      onLongPressMoveUpdate: (details) {
        _updateSelection(details);
      },
      onLongPressCancel: () {
        _hideMenu();
      },
      onLongPressUp: () {
        if (indexNotifier.value != -1) {
          widget.onSelected(indexNotifier.value);
        }
        _hideMenu();
      },
      child: widget.builder(context, key),
    );
  }

  void _showMenu(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    _hideMenu();

    indexNotifier.value = widget.itemLength - 1;
    popupMenuOverlayEntry ??= OverlayEntry(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final right = screenSize.width - rect.right;
        final bottom = screenSize.height - rect.top + 16;
        return Positioned(
          right: right,
          bottom: bottom,
          child: ColoredBox(
            color: theme.toolbarMenuBackgroundColor,
            child: ValueListenableBuilder(
              valueListenable: indexNotifier,
              builder: (context, value, _) => widget.menuBuilder(
                context,
                itemKeys,
                value,
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(popupMenuOverlayEntry!);
  }

  void _hideMenu() {
    indexNotifier.value = -1;

    popupMenuOverlayEntry?.remove();
    popupMenuOverlayEntry = null;
  }

  void _updateSelection(LongPressMoveUpdateDetails details) {
    final dx = details.globalPosition.dx;
    for (var i = 0; i < itemKeys.length; i++) {
      final key = itemKeys[i];
      final RenderBox renderBox =
          key.currentContext!.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);
      final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
      // ignore the position overflow
      if ((i == 0 && dx < rect.left) ||
          (i == itemKeys.length - 1 && dx > rect.right)) {
        indexNotifier.value = -1;
        break;
      }
      if (rect.left <= dx && dx <= rect.right) {
        indexNotifier.value = itemKeys.indexOf(key);
        break;
      }
    }
  }
}

import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flutter/material.dart';

class OptionItem {
  const OptionItem(this.icon, this.title);

  final Icon? icon;
  final String title;
}

class OptionOverlay<T> extends StatelessWidget {
  const OptionOverlay({
    super.key,
    required this.items,
    this.onHover,
    this.onTap,
  });

  final List<T> items;
  final IndexedValueCallback<T>? onHover;
  final IndexedValueCallback<T>? onTap;

  static void showWithAnchor<T>(
    BuildContext context, {
    required List<T> items,
    required String identifier,
    required BuildContext anchorContext,
    IndexedValueCallback<T>? onHover,
    IndexedValueCallback<T>? onTap,
    AnchorDirection? anchorDirection,
    OverlapBehaviour? overlapBehaviour,
    FlowyOverlayDelegate? delegate,
  }) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OptionOverlay(
        items: items,
        onHover: onHover,
        onTap: onTap,
      ),
      identifier: identifier,
      anchorContext: anchorContext,
      anchorDirection: anchorDirection,
      delegate: delegate,
      overlapBehaviour: overlapBehaviour,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_OptionListItem> listItems =
        items.map((e) => _OptionListItem(e)).toList();
    return ListOverlay(
      itemBuilder: (context, index) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover:
              onHover != null ? (_) => onHover!(items[index], index) : null,
          child: GestureDetector(
            onTap: onTap != null ? () => onTap!(items[index], index) : null,
            child: listItems[index],
          ),
        );
      },
      itemCount: listItems.length,
    );
  }
}

class _OptionListItem<T> extends StatelessWidget {
  const _OptionListItem(
    this.value, {
    super.key,
  });

  final T value;

  @override
  Widget build(BuildContext context) {
    if (T == String || T == OptionItem) {
      var children = <Widget>[];
      if (value is String) {
        children = [
          Text(value as String),
        ];
      } else if (value is OptionItem) {
        final optionItem = value as OptionItem;
        children = [
          if (optionItem.icon != null) optionItem.icon!,
          Text(optionItem.title),
        ];
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    throw UnimplementedError('The type $T is not supported by option list.');
  }
}

import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

enum AccessoryType {
  edit,
  more,
}

abstract class CardAccessory implements Widget {
  AccessoryType get type;
  void onTap(final BuildContext context) {}
}

typedef CardAccessoryBuilder = List<CardAccessory> Function(
  BuildContext buildContext,
);

class CardAccessoryContainer extends StatelessWidget {
  final void Function(AccessoryType) onTapAccessory;
  final List<CardAccessory> accessories;
  const CardAccessoryContainer({
    required this.accessories,
    required this.onTapAccessory,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final children = accessories.map((final accessory) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          accessory.onTap(context);
          onTapAccessory(accessory.type);
        },
        child: _wrapHover(context, accessory),
      );
    }).toList();
    return _wrapDecoration(context, Row(children: children));
  }

  FlowyHover _wrapHover(final BuildContext context, final CardAccessory accessory) {
    return FlowyHover(
      style: HoverStyle(
        backgroundColor: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.zero,
      ),
      builder: (final _, final onHover) => SizedBox(
        width: 24,
        height: 24,
        child: accessory,
      ),
    );
  }

  Widget _wrapDecoration(final BuildContext context, final Widget child) {
    final borderSide = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 1.0,
    );
    final decoration = BoxDecoration(
      color: Colors.transparent,
      border: Border.fromBorderSide(borderSide),
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    );
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: decoration,
      child: child,
    );
  }
}

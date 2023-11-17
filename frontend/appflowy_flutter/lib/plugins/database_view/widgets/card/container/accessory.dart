import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

enum AccessoryType {
  edit,
  more,
}

abstract mixin class CardAccessory implements Widget {
  AccessoryType get type;
  void onTap(BuildContext context) {}
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final children = accessories.map<Widget>((accessory) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          accessory.onTap(context);
          onTapAccessory(accessory.type);
        },
        child: _wrapHover(context, accessory),
      );
    }).toList();

    children.insert(
      1,
      VerticalDivider(
        width: 1,
        thickness: 1,
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF1F2329).withOpacity(0.12)
            : const Color(0xff59647a),
      ),
    );

    return _wrapDecoration(
      context,
      IntrinsicHeight(child: Row(children: children)),
    );
  }

  Widget _wrapHover(BuildContext context, CardAccessory accessory) {
    return SizedBox(
      width: 24,
      height: 22,
      child: FlowyHover(
        style: HoverStyle(
          backgroundColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.zero,
        ),
        child: accessory,
      ),
    );
  }

  Widget _wrapDecoration(BuildContext context, Widget child) {
    final decoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      border: Border.fromBorderSide(
        BorderSide(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF1F2329).withOpacity(0.12)
              : const Color(0xff59647a),
          width: 1.0,
        ),
      ),
      boxShadow: [
        BoxShadow(
          blurRadius: 4,
          spreadRadius: 0,
          color: const Color(0xFF1F2329).withOpacity(0.02),
        ),
        BoxShadow(
          blurRadius: 4,
          spreadRadius: -2,
          color: const Color(0xFF1F2329).withOpacity(0.02),
        ),
      ],
    );
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        child: child,
      ),
    );
  }
}

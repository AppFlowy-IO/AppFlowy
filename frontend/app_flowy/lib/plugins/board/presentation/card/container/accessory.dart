import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AccessoryType {
  edit,
  more,
}

abstract class CardAccessory implements Widget {
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
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    final children = accessories.map((accessory) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          accessory.onTap(context);
          onTapAccessory(accessory.type);
        },
        child: _wrapHover(theme, accessory),
      );
    }).toList();
    return _wrapDecoration(context, Row(children: children));
  }

  FlowyHover _wrapHover(AppTheme theme, CardAccessory accessory) {
    return FlowyHover(
      style: HoverStyle(
        hoverColor: theme.hover,
        backgroundColor: theme.surface,
        borderRadius: BorderRadius.zero,
      ),
      builder: (_, onHover) => SizedBox(
        width: 24,
        height: 24,
        child: accessory,
      ),
    );
  }

  Widget _wrapDecoration(BuildContext context, Widget child) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    final borderSide = BorderSide(color: theme.shader6, width: 1.0);
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

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';

import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import '../cell_builder.dart';

class GridCellAccessoryBuildContext {
  final BuildContext anchorContext;
  final bool isCellEditing;

  GridCellAccessoryBuildContext({
    required this.anchorContext,
    required this.isCellEditing,
  });
}

class GridCellAccessoryBuilder<T extends State<StatefulWidget>> {
  final GlobalKey<T> _key = GlobalKey();

  final Widget Function(Key key) _builder;

  GridCellAccessoryBuilder({required Widget Function(Key key) builder})
      : _builder = builder;

  Widget build() => _builder(_key);

  void onTap() {
    (_key.currentState as GridCellAccessoryState).onTap();
  }

  bool enable() {
    if (_key.currentState == null) {
      return true;
    }
    return (_key.currentState as GridCellAccessoryState).enable();
  }
}

abstract mixin class GridCellAccessoryState {
  void onTap();

  // The accessory will be hidden if enable() return false;
  bool enable() => true;
}

class PrimaryCellAccessory extends StatefulWidget {
  final VoidCallback onTapCallback;
  final bool isCellEditing;
  const PrimaryCellAccessory({
    required this.onTapCallback,
    required this.isCellEditing,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PrimaryCellAccessoryState();
}

class _PrimaryCellAccessoryState extends State<PrimaryCellAccessory>
    with GridCellAccessoryState {
  @override
  Widget build(BuildContext context) {
    return FlowyTooltip.delayed(
      message: LocaleKeys.tooltip_openAsPage.tr(),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: FlowySvg(
            FlowySvgs.full_view_s,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  void onTap() => widget.onTapCallback();

  @override
  bool enable() => !widget.isCellEditing;
}

class AccessoryHover extends StatefulWidget {
  final CellAccessory child;
  const AccessoryHover({required this.child, super.key});

  @override
  State<AccessoryHover> createState() => _AccessoryHoverState();
}

class _AccessoryHoverState extends State<AccessoryHover> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      DecoratedBox(
        decoration: BoxDecoration(
          color: _isHover
              ? AFThemeExtension.of(context).lightGreyHover
              : Colors.transparent,
          borderRadius: Corners.s6Border,
        ),
        child: widget.child,
      ),
    ];

    final accessoryBuilder = widget.child.accessoryBuilder;
    if (accessoryBuilder != null && _isHover) {
      final accessories = accessoryBuilder(
        (GridCellAccessoryBuildContext(
          anchorContext: context,
          isCellEditing: false,
        )),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CellAccessoryContainer(accessories: accessories),
        ).positioned(right: 0),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (p) => setState(() => _isHover = true),
      onExit: (p) => setState(() => _isHover = false),
      child: Stack(
        fit: StackFit.loose,
        alignment: AlignmentDirectional.center,
        children: children,
      ),
    );
  }
}

class CellAccessoryContainer extends StatelessWidget {
  final List<GridCellAccessoryBuilder> accessories;
  const CellAccessoryContainer({required this.accessories, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final children =
        accessories.where((accessory) => accessory.enable()).map((accessory) {
      final hover = FlowyHover(
        style:
            HoverStyle(hoverColor: AFThemeExtension.of(context).lightGreyHover),
        builder: (_, onHover) => accessory.build(),
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => accessory.onTap(),
        child: hover,
      );
    }).toList();

    return Wrap(spacing: 6, children: children);
  }
}

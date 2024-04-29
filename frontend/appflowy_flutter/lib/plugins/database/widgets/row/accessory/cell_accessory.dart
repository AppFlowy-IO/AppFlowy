import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../cell/editable_cell_builder.dart';

class GridCellAccessoryBuildContext {
  GridCellAccessoryBuildContext({
    required this.anchorContext,
    required this.isCellEditing,
  });

  final BuildContext anchorContext;
  final bool isCellEditing;
}

class GridCellAccessoryBuilder<T extends State<StatefulWidget>> {
  GridCellAccessoryBuilder({required Widget Function(Key key) builder})
      : _builder = builder;

  final GlobalKey<T> _key = GlobalKey();

  final Widget Function(Key key) _builder;

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
  const PrimaryCellAccessory({
    super.key,
    required this.onTap,
    required this.isCellEditing,
  });

  final VoidCallback onTap;
  final bool isCellEditing;

  @override
  State<StatefulWidget> createState() => _PrimaryCellAccessoryState();
}

class _PrimaryCellAccessoryState extends State<PrimaryCellAccessory>
    with GridCellAccessoryState {
  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.tooltip_openAsPage.tr(),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).dividerColor),
          ),
          borderRadius: Corners.s6Border,
        ),
        child: Center(
          child: FlowySvg(
            FlowySvgs.full_view_s,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  void onTap() => widget.onTap();

  @override
  bool enable() => !widget.isCellEditing;
}

class AccessoryHover extends StatefulWidget {
  const AccessoryHover({
    super.key,
    required this.child,
    required this.fieldType,
  });

  final CellAccessory child;
  final FieldType fieldType;

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
          color: _isHover && widget.fieldType != FieldType.Checklist
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
        GridCellAccessoryBuildContext(
          anchorContext: context,
          isCellEditing: false,
        ),
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
        alignment: AlignmentDirectional.center,
        children: children,
      ),
    );
  }
}

class CellAccessoryContainer extends StatelessWidget {
  const CellAccessoryContainer({required this.accessories, super.key});

  final List<GridCellAccessoryBuilder> accessories;

  @override
  Widget build(BuildContext context) {
    final children =
        accessories.where((accessory) => accessory.enable()).map((accessory) {
      final hover = FlowyHover(
        style: HoverStyle(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          backgroundColor: Theme.of(context).cardColor,
        ),
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

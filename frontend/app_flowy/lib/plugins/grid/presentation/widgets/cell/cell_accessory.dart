import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowy_infra/size.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import 'cell_builder.dart';

class GridCellAccessoryBuildContext {
  final BuildContext anchorContext;
  final bool isCellEditing;

  GridCellAccessoryBuildContext({
    required this.anchorContext,
    required this.isCellEditing,
  });
}

abstract class GridCellAccessory implements Widget {
  void onTap();

  // The accessory will be hidden if enable() return false;
  bool enable() => true;
}

class PrimaryCellAccessory extends StatelessWidget with GridCellAccessory {
  final VoidCallback onTapCallback;
  final bool isCellEditing;
  const PrimaryCellAccessory({
    required this.onTapCallback,
    required this.isCellEditing,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCellEditing) {
      return const SizedBox();
    } else {
      final theme = context.watch<AppTheme>();
      return Tooltip(
        message: LocaleKeys.tooltip_openAsPage.tr(),
        child: svgWidget(
          "grid/expander",
          color: theme.main1,
        ),
      );
    }
  }

  @override
  void onTap() => onTapCallback();

  @override
  bool enable() => !isCellEditing;
}

class AccessoryHover extends StatefulWidget {
  final CellAccessory child;
  final EdgeInsets contentPadding;
  const AccessoryHover({
    required this.child,
    this.contentPadding = EdgeInsets.zero,
    Key? key,
  }) : super(key: key);

  @override
  State<AccessoryHover> createState() => _AccessoryHoverState();
}

class _AccessoryHoverState extends State<AccessoryHover> {
  late AccessoryHoverState _hoverState;
  VoidCallback? _listenerFn;

  @override
  void initState() {
    _hoverState = AccessoryHoverState();
    _listenerFn = () =>
        _hoverState.onHover = widget.child.onAccessoryHover?.value ?? false;
    widget.child.onAccessoryHover?.addListener(_listenerFn!);

    super.initState();
  }

  @override
  void dispose() {
    _hoverState.dispose();

    if (_listenerFn != null) {
      widget.child.onAccessoryHover?.removeListener(_listenerFn!);
      _listenerFn = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      const _Background(),
      Padding(padding: widget.contentPadding, child: widget.child),
    ];

    final accessoryBuilder = widget.child.accessoryBuilder;
    if (accessoryBuilder != null) {
      final accessories = accessoryBuilder((GridCellAccessoryBuildContext(
        anchorContext: context,
        isCellEditing: false,
      )));
      children.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CellAccessoryContainer(accessories: accessories),
        ).positioned(right: 0),
      );
    }

    return ChangeNotifierProvider.value(
      value: _hoverState,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        opaque: false,
        onEnter: (p) => setState(() => _hoverState.onHover = true),
        onExit: (p) => setState(() => _hoverState.onHover = false),
        child: Stack(
          fit: StackFit.loose,
          alignment: AlignmentDirectional.center,
          children: children,
        ),
      ),
    );
  }
}

class AccessoryHoverState extends ChangeNotifier {
  bool _onHover = false;

  set onHover(bool value) {
    if (_onHover != value) {
      _onHover = value;
      notifyListeners();
    }
  }

  bool get onHover => _onHover;
}

class _Background extends StatelessWidget {
  const _Background({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Consumer<AccessoryHoverState>(
      builder: (context, state, child) {
        if (state.onHover) {
          return FlowyHoverContainer(
            style: HoverStyle(
                borderRadius: Corners.s6Border, hoverColor: theme.shader6),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}

class CellAccessoryContainer extends StatelessWidget {
  final List<GridCellAccessory> accessories;
  const CellAccessoryContainer({required this.accessories, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final children =
        accessories.where((accessory) => accessory.enable()).map((accessory) {
      final hover = FlowyHover(
        style:
            HoverStyle(hoverColor: theme.bg3, backgroundColor: theme.surface),
        builder: (_, onHover) => Container(
          width: 26,
          height: 26,
          padding: const EdgeInsets.all(3),
          child: accessory,
        ),
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

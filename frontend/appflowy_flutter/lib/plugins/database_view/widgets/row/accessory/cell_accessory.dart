import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class GridCellAccessoryBuilder {
  final GlobalKey _key = GlobalKey();

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
    return Tooltip(
      message: LocaleKeys.tooltip_openAsPage.tr(),
      child: svgWidget(
        "grid/expander",
        color: Theme.of(context).colorScheme.primary,
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
    final List<Widget> children = [
      Padding(padding: widget.contentPadding, child: widget.child),
    ];

    final accessoryBuilder = widget.child.accessoryBuilder;
    if (accessoryBuilder != null) {
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
        builder: (_, onHover) => Container(
          width: 26,
          height: 26,
          padding: const EdgeInsets.all(3),
          child: accessory.build(),
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

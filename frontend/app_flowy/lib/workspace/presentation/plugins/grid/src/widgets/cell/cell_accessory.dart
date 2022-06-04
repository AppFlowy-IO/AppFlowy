import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/widgets.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowy_infra/size.dart';
import 'package:styled_widget/styled_widget.dart';

class GridCellAccessoryBuildContext {
  final BuildContext anchorContext;

  GridCellAccessoryBuildContext({required this.anchorContext});
}

abstract class GridCellAccessory implements Widget {
  void onTap();
}

typedef AccessoryBuilder = List<GridCellAccessory> Function(GridCellAccessoryBuildContext buildContext);

abstract class CellAccessory extends Widget {
  const CellAccessory({Key? key}) : super(key: key);

  // The hover will show if the onFocus's value is true
  ValueNotifier<bool>? get isFocus;

  AccessoryBuilder? get accessoryBuilder;
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
    _listenerFn = () => _hoverState.isFocus = widget.child.isFocus?.value ?? false;
    widget.child.isFocus?.addListener(_listenerFn!);

    super.initState();
  }

  @override
  void dispose() {
    _hoverState.dispose();

    if (_listenerFn != null) {
      widget.child.isFocus?.removeListener(_listenerFn!);
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
      final accessories = accessoryBuilder((GridCellAccessoryBuildContext(anchorContext: context)));
      children.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: AccessoryContainer(accessories: accessories),
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
  bool _isFocus = false;

  set onHover(bool value) {
    if (_onHover != value) {
      _onHover = value;
      notifyListeners();
    }
  }

  bool get onHover => _onHover;

  set isFocus(bool value) {
    if (_isFocus != value) {
      _isFocus = value;
      notifyListeners();
    }
  }

  bool get isFocus => _isFocus;
}

class _Background extends StatelessWidget {
  const _Background({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Consumer<AccessoryHoverState>(
      builder: (context, state, child) {
        if (state.onHover || state.isFocus) {
          return FlowyHoverContainer(
            style: HoverStyle(borderRadius: Corners.s6Border, hoverColor: theme.shader6),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}

class AccessoryContainer extends StatelessWidget {
  final List<GridCellAccessory> accessories;
  const AccessoryContainer({required this.accessories, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final children = accessories.map((accessory) {
      final hover = FlowyHover(
        style: HoverStyle(hoverColor: theme.bg3, backgroundColor: theme.surface),
        builder: (_, onHover) => Container(
          width: 26,
          height: 26,
          padding: const EdgeInsets.all(3),
          child: accessory,
        ),
      );
      return GestureDetector(
        child: hover,
        behavior: HitTestBehavior.opaque,
        onTap: () => accessory.onTap(),
      );
    }).toList();

    return Wrap(children: children, spacing: 6);
  }
}

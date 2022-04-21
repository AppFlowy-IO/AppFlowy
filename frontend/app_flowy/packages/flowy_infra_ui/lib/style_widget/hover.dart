import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:provider/provider.dart';

typedef HoverBuilder = Widget Function(BuildContext context, bool onHover);

class FlowyHover extends StatefulWidget {
  final HoverStyle style;
  final HoverBuilder? builder;
  final Widget? child;
  final bool Function()? setSelected;

  const FlowyHover({
    Key? key,
    this.builder,
    this.child,
    required this.style,
    this.setSelected,
  }) : super(key: key);

  @override
  State<FlowyHover> createState() => _FlowyHoverState();
}

class _FlowyHoverState extends State<FlowyHover> {
  bool _onHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (p) => setState(() => _onHover = true),
      onExit: (p) => setState(() => _onHover = false),
      child: renderWidget(),
    );
  }

  Widget renderWidget() {
    var showHover = _onHover;
    if (!showHover && widget.setSelected != null) {
      showHover = widget.setSelected!();
    }

    final child = widget.child ?? widget.builder!(context, _onHover);
    if (showHover) {
      return FlowyHoverContainer(
        style: widget.style,
        child: child,
      );
    } else {
      return child;
    }
  }
}

class HoverStyle {
  final Color borderColor;
  final double borderWidth;
  final Color hoverColor;
  final BorderRadius borderRadius;
  final EdgeInsets contentMargin;

  const HoverStyle(
      {this.borderColor = Colors.transparent,
      this.borderWidth = 0,
      this.borderRadius = const BorderRadius.all(Radius.circular(6)),
      this.contentMargin = EdgeInsets.zero,
      required this.hoverColor});
}

class FlowyHoverContainer extends StatelessWidget {
  final HoverStyle style;
  final Widget? child;

  const FlowyHoverContainer({
    Key? key,
    this.child,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hoverBorder = Border.all(
      color: style.borderColor,
      width: style.borderWidth,
    );

    return Container(
      margin: style.contentMargin,
      decoration: BoxDecoration(
        border: hoverBorder,
        color: style.hoverColor,
        borderRadius: style.borderRadius,
      ),
      child: child,
    );
  }
}

//
abstract class HoverWidget extends StatefulWidget {
  const HoverWidget({Key? key}) : super(key: key);

  ValueNotifier<bool> get onFocus;
}

class FlowyHover2 extends StatefulWidget {
  final HoverWidget child;
  const FlowyHover2({required this.child, Key? key}) : super(key: key);

  @override
  State<FlowyHover2> createState() => _FlowyHover2State();
}

class _FlowyHover2State extends State<FlowyHover2> {
  late FlowyHoverState _hoverState;

  @override
  void initState() {
    _hoverState = FlowyHoverState();
    widget.child.onFocus.addListener(() {
      _hoverState.onFocus = widget.child.onFocus.value;
    });
    super.initState();
  }

  @override
  void dispose() {
    _hoverState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _hoverState,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        opaque: false,
        onEnter: (p) => setState(() => _hoverState.onHover = true),
        onExit: (p) => setState(() => _hoverState.onHover = false),
        child: Stack(
          fit: StackFit.expand,
          alignment: AlignmentDirectional.center,
          children: [
            const _HoverBackground(),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _HoverBackground extends StatelessWidget {
  const _HoverBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Consumer<FlowyHoverState>(
      builder: (context, state, child) {
        if (state.onHover || state.onFocus) {
          return FlowyHoverContainer(
            style: HoverStyle(
              borderRadius: Corners.s6Border,
              hoverColor: theme.shader6,
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}

class FlowyHoverState extends ChangeNotifier {
  bool _onHover = false;
  bool _onFocus = false;

  set onHover(bool value) {
    if (_onHover != value) {
      _onHover = value;
      notifyListeners();
    }
  }

  bool get onHover => _onHover;

  set onFocus(bool value) {
    if (_onFocus != value) {
      _onFocus = value;
      notifyListeners();
    }
  }

  bool get onFocus => _onFocus;
}

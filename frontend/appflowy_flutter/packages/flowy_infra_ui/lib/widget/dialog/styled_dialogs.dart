import 'dart:ui';

import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/dialog/dialog_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension IntoDialog on Widget {
  Future<dynamic> show(BuildContext context) async {
    FocusNode dialogFocusNode = FocusNode();
    await Dialogs.show(
      child: KeyboardListener(
        focusNode: dialogFocusNode,
        onKeyEvent: (event) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        },
        child: this,
      ),
      context,
    );
    dialogFocusNode.dispose();
  }
}

class StyledDialog extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? bgColor;
  final bool shrinkWrap;

  const StyledDialog({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.margin,
    this.bgColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget innerContent = Container(
      padding: padding ??
          EdgeInsets.symmetric(horizontal: Insets.xxl, vertical: Insets.xl),
      color: bgColor ?? Theme.of(context).colorScheme.surface,
      child: child,
    );

    if (shrinkWrap) {
      innerContent =
          IntrinsicWidth(child: IntrinsicHeight(child: innerContent));
    }

    return FocusTraversalGroup(
      child: Container(
        margin: margin ?? EdgeInsets.all(Insets.sm * 2),
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(
            minWidth: DialogSize.minDialogWidth,
            maxHeight: maxHeight ?? double.infinity,
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: SingleChildScrollView(
              physics: StyledScrollPhysics(),
              //https://medium.com/saugo360/https-medium-com-saugo360-flutter-using-overlay-to-display-floating-widgets-2e6d0e8decb9
              child: Material(
                type: MaterialType.transparency,
                child: innerContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Dialogs {
  static Future<dynamic> show(BuildContext context,
      {required Widget child}) async {
    return await Navigator.of(context).push(
      StyledDialogRoute(
        barrier: DialogBarrier(color: Colors.black.withOpacity(0.4)),
        pageBuilder: (BuildContext buildContext, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return SafeArea(child: child);
        },
      ),
    );
  }
}

class DialogBarrier {
  String label;
  Color color;
  bool dismissible;
  ImageFilter? filter;

  DialogBarrier({
    this.dismissible = true,
    this.color = Colors.transparent,
    this.label = '',
    this.filter,
  });
}

class StyledDialogRoute<T> extends PopupRoute<T> {
  final RoutePageBuilder _pageBuilder;
  final DialogBarrier barrier;

  StyledDialogRoute({
    required RoutePageBuilder pageBuilder,
    required this.barrier,
    Duration transitionDuration = const Duration(milliseconds: 300),
    RouteTransitionsBuilder? transitionBuilder,
    super.settings,
  })  : _pageBuilder = pageBuilder,
        _transitionDuration = transitionDuration,
        _transitionBuilder = transitionBuilder,
        super(filter: barrier.filter);

  @override
  bool get barrierDismissible {
    return barrier.dismissible;
  }

  @override
  String get barrierLabel => barrier.label;

  @override
  Color get barrierColor => barrier.color;

  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;

  final RouteTransitionsBuilder? _transitionBuilder;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _pageBuilder(context, animation, secondaryAnimation),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (_transitionBuilder == null) {
      return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child);
    } else {
      return _transitionBuilder!(context, animation, secondaryAnimation, child);
    } // Some default transition
  }
}

import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/buttons/ok_cancel_button.dart';
import 'package:flowy_infra_ui/widget/dialog/dialog_size.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:textstyle_extensions/textstyle_extensions.dart';

import 'dialog_context.dart';
export 'dialog_context.dart';

class Dialogs {
  static Future<dynamic> show(Widget child, BuildContext context) async {
    return await Navigator.of(context).push(
      StyledDialogRoute(
        pageBuilder: (BuildContext buildContext, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return SafeArea(child: child);
        },
      ),
    );
    /*return await showDialog(
      context: context ?? MainViewContext.value,
      builder: (context) => child,
    );*/
  }

  static Future<dynamic> showWithContext(
      DialogContext dialogContext, BuildContext context) async {
    return await Navigator.of(context).push(
      StyledDialogRoute(
        barrierDismissible: dialogContext.barrierDismissable,
        pageBuilder: (BuildContext buildContext, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return SafeArea(child: dialogContext.buildWiget(buildContext));
        },
      ),
    );
  }
}

class StyledDialogRoute<T> extends PopupRoute<T> {
  StyledDialogRoute({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = false,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    RouteSettings? settings,
  })  : _pageBuilder = pageBuilder,
        _barrierDismissible = barrierDismissible,
        _barrierLabel = barrierLabel ?? '',
        _barrierColor = barrierColor,
        _transitionDuration = transitionDuration,
        _transitionBuilder = transitionBuilder,
        super(settings: settings);

  final RoutePageBuilder _pageBuilder;

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  String get barrierLabel => _barrierLabel;
  final String _barrierLabel;

  @override
  Color get barrierColor => _barrierColor;
  final Color _barrierColor;

  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;

  final RouteTransitionsBuilder? _transitionBuilder;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Semantics(
      child: _pageBuilder(context, animation, secondaryAnimation),
      scopesRoute: true,
      explicitChildNodes: true,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (_transitionBuilder == null) {
      return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
          child: child);
    } else {
      return _transitionBuilder!(context, animation, secondaryAnimation, child);
    } // Some default transition
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
    Key? key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.margin,
    this.bgColor,
    this.borderRadius,
    this.shrinkWrap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? Corners.s8Border;
    final theme = context.watch<AppTheme>();

    Widget innerContent = Container(
      padding: padding ?? EdgeInsets.all(Insets.lGutter),
      color: bgColor ?? theme.bg1,
      child: child,
    );

    if (shrinkWrap) {
      innerContent =
          IntrinsicWidth(child: IntrinsicHeight(child: innerContent));
    }

    return FocusTraversalGroup(
      child: Container(
        margin: margin ?? EdgeInsets.all(Insets.lGutter * 2),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: DialogSize.minDialogWidth,
            maxHeight: maxHeight ?? double.infinity,
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: ClipRRect(
            borderRadius: radius,
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

class OkCancelDialog extends StatelessWidget {
  final VoidCallback? onOkPressed;
  final VoidCallback? onCancelPressed;
  final String? okTitle;
  final String? cancelTitle;
  final String? title;
  final String message;
  final double? maxWidth;

  const OkCancelDialog(
      {Key? key,
      this.onOkPressed,
      this.onCancelPressed,
      this.okTitle,
      this.cancelTitle,
      this.title,
      required this.message,
      this.maxWidth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return StyledDialog(
      maxWidth: maxWidth ?? 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...[
            Text(title!.toUpperCase(),
                style: TextStyles.T1.textColor(theme.shader1)),
            VSpace(Insets.sm * 1.5),
            Container(color: theme.bg1, height: 1),
            VSpace(Insets.m * 1.5),
          ],
          Text(message, style: TextStyles.Body1.textHeight(1.5)),
          SizedBox(height: Insets.l),
          OkCancelButton(
            onOkPressed: onOkPressed,
            onCancelPressed: onCancelPressed,
            okTitle: okTitle?.toUpperCase(),
            cancelTitle: cancelTitle?.toUpperCase(),
          )
        ],
      ),
    );
  }
}

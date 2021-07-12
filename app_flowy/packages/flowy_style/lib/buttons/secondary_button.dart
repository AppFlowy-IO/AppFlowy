import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:textstyle_extensions/textstyle_extensions.dart';

import '../size.dart';
import '../styled_image_icon.dart';
import '../text_style.dart';
import '../theme.dart';
import 'base_styled_button.dart';

class SecondaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryTextButton(this.label, {Key? key, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    TextStyle txtStyle = TextStyles.Footnote.textColor(theme.accent1Darker);
    return SecondaryButton(
        onPressed: onPressed, child: Text(label, style: txtStyle));
  }
}

class SecondaryIconButton extends StatelessWidget {
  /// Must be either an `AssetImage` for an `ImageIcon` or an `IconData` for a regular `Icon`
  final AssetImage icon;
  final Function()? onPressed;
  final Color? color;

  const SecondaryIconButton(this.icon, {Key? key, this.onPressed, this.color})
      : assert((icon is AssetImage) || (icon is IconData)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SecondaryButton(
      onPressed: onPressed,
      minHeight: 36,
      minWidth: 36,
      contentPadding: Insets.sm,
      child: StyledImageIcon(icon, size: 20, color: color ?? theme.grey),
    );
  }
}

class SecondaryButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? minWidth;
  final double? minHeight;
  final double? contentPadding;
  final Function(bool)? onFocusChanged;

  const SecondaryButton(
      {Key? key,
      required this.child,
      this.onPressed,
      this.minWidth,
      this.minHeight,
      this.contentPadding,
      this.onFocusChanged})
      : super(key: key);

  @override
  _SecondaryButtonState createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isMouseOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return MouseRegion(
      onEnter: (_) => setState(() => _isMouseOver = true),
      onExit: (_) => setState(() => _isMouseOver = false),
      child: BaseStyledButton(
        minWidth: widget.minWidth ?? 78,
        minHeight: widget.minHeight ?? 42,
        contentPadding: EdgeInsets.all(widget.contentPadding ?? Insets.m),
        bgColor: theme.surface,
        outlineColor:
            (_isMouseOver ? theme.accent1 : theme.grey).withOpacity(.35),
        hoverColor: theme.surface,
        onFocusChanged: widget.onFocusChanged,
        downColor: theme.greyWeak.withOpacity(.35),
        borderRadius: Corners.s5,
        child: IgnorePointer(child: widget.child),
        onPressed: widget.onPressed,
      ),
    );
  }
}

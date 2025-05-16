import 'package:flutter/material.dart';
import 'package:appflowy_ui/src/theme/definition/theme_data.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';

/// Avatar sizes in pixels
enum AFAvatarSize {
  xs,
  s,
  m,
  l,
  xl;

  double get size {
    switch (this) {
      case AFAvatarSize.xs:
        return 16.0;
      case AFAvatarSize.s:
        return 24.0;
      case AFAvatarSize.m:
        return 32.0;
      case AFAvatarSize.l:
        return 48.0;
      case AFAvatarSize.xl:
        return 64.0;
    }
  }

  TextStyle buildTextStyle(AppFlowyThemeData theme, Color color) {
    switch (this) {
      case AFAvatarSize.xs:
        return theme.textStyle.caption.standard(color: color);
      case AFAvatarSize.s:
        return theme.textStyle.body.standard(color: color);
      case AFAvatarSize.m:
        return theme.textStyle.heading4.standard(color: color);
      case AFAvatarSize.l:
        return theme.textStyle.heading3.standard(color: color);
      case AFAvatarSize.xl:
        return theme.textStyle.heading2.standard(color: color);
    }
  }
}

/// Avatar widget
class AFAvatar extends StatelessWidget {
  /// Displays an avatar. Precedence: [child] > [url] > [name].
  ///
  /// If [child] is provided, it is shown. Otherwise, if [url] is provided and non-empty, the image is shown. Otherwise, initials from [name] are shown.
  const AFAvatar({
    super.key,
    this.name,
    this.url,
    this.size = AFAvatarSize.m,
    this.textColor,
    this.backgroundColor,
    this.child,
  });

  /// The name of the avatar. Used for initials if [child] and [url] are not provided.
  final String? name;

  /// The URL of the avatar image. Used if [child] is not provided.
  final String? url;

  /// Custom widget to display as the avatar. Takes highest precedence.
  final Widget? child;

  /// The size of the avatar.
  final AFAvatarSize size;

  /// The text color for initials. Only applies when showing initials.
  final Color? textColor;

  /// The background color for initials. Only applies when showing initials.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final double avatarSize = size.size;
    final Color bgColor =
        backgroundColor ?? theme.backgroundColorScheme.primary;
    final Color txtColor = textColor ?? theme.textColorScheme.primary;
    final TextStyle textStyle = size.buildTextStyle(theme, txtColor);

    final Widget avatarContent = _buildAvatarContent(
      avatarSize: avatarSize,
      bgColor: bgColor,
      textStyle: textStyle,
    );

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: avatarContent,
    );
  }

  Widget _buildAvatarContent({
    required double avatarSize,
    required Color bgColor,
    required TextStyle textStyle,
  }) {
    if (child != null) {
      return ClipOval(
        child: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: child,
        ),
      );
    } else if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          // fallback to initials if the image is not found
          errorBuilder: (context, error, stackTrace) => _buildInitialsCircle(
            avatarSize,
            bgColor,
            textStyle,
          ),
        ),
      );
    } else {
      return _buildInitialsCircle(
        avatarSize,
        bgColor,
        textStyle,
      );
    }
  }

  Widget _buildInitialsCircle(double size, Color bgColor, TextStyle textStyle) {
    final initials = _getInitials(name);
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

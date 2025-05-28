import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:appflowy_ui/src/theme/definition/theme_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    this.colorHash,
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
  /// If not provided, a matching thick color from badge color scheme will be used.
  final Color? textColor;

  /// The background color for initials. Only applies when showing initials.
  /// If not provided, a light color from badge color scheme will be used.
  final Color? backgroundColor;

  /// The hash value used to pick the color. If it's not provided, the name hash will be used.
  final String? colorHash;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final double avatarSize = size.size;

    // Pick color index based on name hash (1-20)
    final int colorIndex = _pickColorIndexFromName(colorHash ?? name);
    final Color backgroundColor =
        this.backgroundColor ?? _getBadgeBackgroundColor(theme, colorIndex);
    final Color textColor =
        this.textColor ?? _getBadgeTextColor(theme, colorIndex);

    final TextStyle textStyle = size.buildTextStyle(theme, textColor);

    final Widget avatarContent = _buildAvatarContent(
      avatarSize: avatarSize,
      bgColor: backgroundColor,
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
        child: CachedNetworkImage(
          imageUrl: url!,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          // fallback to initials if the image is not found
          errorWidget: (context, error, stackTrace) => _buildInitialsCircle(
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
    final initial = _getInitials(name);
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '';

    // Always return just the first letter of the name
    return name.trim()[0].toUpperCase();
  }

  /// Deterministically pick a color index (1-20) based on the user name
  int _pickColorIndexFromName(String? name) {
    if (name == null || name.isEmpty) return 1;
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return (hash.abs() % 20) + 1;
  }

  /// Gets the background color from badge color scheme using a list
  Color _getBadgeBackgroundColor(AppFlowyThemeData theme, int colorIndex) {
    final List<Color> backgroundColors = [
      theme.badgeColorScheme.color1Light2,
      theme.badgeColorScheme.color2Light2,
      theme.badgeColorScheme.color3Light2,
      theme.badgeColorScheme.color4Light2,
      theme.badgeColorScheme.color5Light2,
      theme.badgeColorScheme.color6Light2,
      theme.badgeColorScheme.color7Light2,
      theme.badgeColorScheme.color8Light2,
      theme.badgeColorScheme.color9Light2,
      theme.badgeColorScheme.color10Light2,
      theme.badgeColorScheme.color11Light2,
      theme.badgeColorScheme.color12Light2,
      theme.badgeColorScheme.color13Light2,
      theme.badgeColorScheme.color14Light2,
      theme.badgeColorScheme.color15Light2,
      theme.badgeColorScheme.color16Light2,
      theme.badgeColorScheme.color17Light2,
      theme.badgeColorScheme.color18Light2,
      theme.badgeColorScheme.color19Light2,
      theme.badgeColorScheme.color20Light2,
    ];
    return backgroundColors[(colorIndex - 1).clamp(0, 19)];
  }

  /// Gets the text color from badge color scheme using a list
  Color _getBadgeTextColor(AppFlowyThemeData theme, int colorIndex) {
    final List<Color> textColors = [
      theme.badgeColorScheme.color1Thick3,
      theme.badgeColorScheme.color2Thick3,
      theme.badgeColorScheme.color3Thick3,
      theme.badgeColorScheme.color4Thick3,
      theme.badgeColorScheme.color5Thick3,
      theme.badgeColorScheme.color6Thick3,
      theme.badgeColorScheme.color7Thick3,
      theme.badgeColorScheme.color8Thick3,
      theme.badgeColorScheme.color9Thick3,
      theme.badgeColorScheme.color10Thick3,
      theme.badgeColorScheme.color11Thick3,
      theme.badgeColorScheme.color12Thick3,
      theme.badgeColorScheme.color13Thick3,
      theme.badgeColorScheme.color14Thick3,
      theme.badgeColorScheme.color15Thick3,
      theme.badgeColorScheme.color16Thick3,
      theme.badgeColorScheme.color17Thick3,
      theme.badgeColorScheme.color18Thick3,
      theme.badgeColorScheme.color19Thick3,
      theme.badgeColorScheme.color20Thick3,
    ];
    return textColors[(colorIndex - 1).clamp(0, 19)];
  }
}

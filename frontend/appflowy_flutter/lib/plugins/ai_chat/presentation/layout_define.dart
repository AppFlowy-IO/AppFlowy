import 'package:appflowy/util/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

class AIChatUILayout {
  const AIChatUILayout._();

  static EdgeInsets safeAreaInsets(BuildContext context) {
    final query = MediaQuery.of(context);
    return UniversalPlatform.isMobile
        ? EdgeInsets.fromLTRB(
            query.padding.left,
            0,
            query.padding.right,
            query.viewInsets.bottom + query.padding.bottom,
          )
        : const EdgeInsets.only(bottom: 24);
  }

  static EdgeInsets get messageMargin => UniversalPlatform.isMobile
      ? const EdgeInsets.symmetric(horizontal: 16)
      : EdgeInsets.zero;

  static TextStyle? inputHintTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).isLightMode
              ? const Color(0xFFBDC2C8)
              : const Color(0xFF3C3E51),
        );
  }
}

class DesktopAIChatSizes {
  const DesktopAIChatSizes._();

  static const avatarSize = 32.0;
  static const avatarAndChatBubbleSpacing = 12.0;

  static const messageActionBarIconSize = 28.0;
  static const messageHoverActionBarPadding = EdgeInsets.all(2.0);
  static const messageHoverActionBarRadius =
      BorderRadius.all(Radius.circular(8.0));
  static const messageHoverActionBarIconRadius =
      BorderRadius.all(Radius.circular(6.0));
  static const messageActionBarIconRadius =
      BorderRadius.all(Radius.circular(8.0));

  static const inputActionBarMargin =
      EdgeInsetsDirectional.fromSTEB(8, 0, 8, 4);
  static const inputActionBarButtonSpacing = 4.0;
}

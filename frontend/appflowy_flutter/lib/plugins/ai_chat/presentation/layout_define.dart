import 'package:appflowy/util/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

class AIChatUILayout {
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

class DesktopAIPromptSizes {
  static const promptFrameRadius = BorderRadius.all(Radius.circular(12.0));

  static const attachedFilesBarPadding =
      EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0);
  static const attachedFilesPreviewHeight = 48.0;
  static const attachedFilesPreviewSpacing = 12.0;

  static const predefinedFormatButtonHeight = 28.0;
  static const predefinedFormatIconHeight = 16.0;
  static const predefinedFormatBarButtonSpacing = 4.0;

  static const textFieldMinHeight = 36.0;
  static const textFieldContentPadding =
      EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 14.0, 8.0);

  static const actionBarHeight = 32.0;
  static const actionBarPadding = EdgeInsetsDirectional.fromSTEB(8, 0, 8, 4);
  static const actionBarButtonSize = 28.0;
  static const actionBarIconSize = 16.0;
  static const actionBarButtonSpacing = 4.0;
  static const sendButtonSize = 24.0;
}

class MobileAIPromptSizes {
  static const promptFrameRadius =
      BorderRadius.vertical(top: Radius.circular(8.0));

  static const attachedFilesBarHeight = 68.0;
  static const attachedFilesBarPadding =
      EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 4.0);
  static const attachedFilesPreviewHeight = 56.0;
  static const attachedFilesPreviewSpacing = 8.0;

  static const predefinedFormatButtonHeight = 32.0;
  static const predefinedFormatIconHeight = 20.0;
  static const predefinedFormatBarButtonSpacing = 8.0;
  static const predefinedFormatBarPadding = EdgeInsets.all(8.0);

  static const textFieldMinHeight = 32.0;
  static const textFieldContentPadding =
      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);

  static const mentionIconSize = 20.0;
  static const sendButtonSize = 32.0;
}

class DesktopAIConvoSizes {
  static const avatarSize = 32.0;

  static const avatarAndChatBubbleSpacing = 12.0;

  static const actionBarIconSize = 28.0;
  static const actionBarIconSpacing = 8.0;
  static const hoverActionBarPadding = EdgeInsets.all(2.0);
  static const hoverActionBarRadius = BorderRadius.all(Radius.circular(8.0));
  static const hoverActionBarIconRadius =
      BorderRadius.all(Radius.circular(6.0));
  static const actionBarIconRadius = BorderRadius.all(Radius.circular(8.0));
}

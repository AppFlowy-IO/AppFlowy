import 'package:flutter/widgets.dart';

class DesktopAIPromptSizes {
  const DesktopAIPromptSizes._();

  static const attachedFilesBarPadding =
      EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0);
  static const attachedFilesPreviewHeight = 48.0;
  static const attachedFilesPreviewSpacing = 12.0;

  static const predefinedFormatButtonHeight = 28.0;
  static const predefinedFormatIconHeight = 16.0;

  static const textFieldMinHeight = 36.0;
  static const textFieldContentPadding =
      EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 14.0, 8.0);

  static const actionBarButtonSize = 28.0;
  static const actionBarIconSize = 16.0;
  static const actionBarSendButtonSize = 32.0;
  static const actionBarSendButtonIconSize = 24.0;
}

class MobileAIPromptSizes {
  const MobileAIPromptSizes._();

  static const attachedFilesBarHeight = 68.0;
  static const attachedFilesBarPadding =
      EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 4.0);
  static const attachedFilesPreviewHeight = 56.0;
  static const attachedFilesPreviewSpacing = 8.0;

  static const predefinedFormatButtonHeight = 32.0;
  static const predefinedFormatIconHeight = 20.0;

  static const textFieldMinHeight = 32.0;
  static const textFieldContentPadding =
      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);

  static const mentionIconSize = 20.0;
  static const sendButtonSize = 32.0;
}

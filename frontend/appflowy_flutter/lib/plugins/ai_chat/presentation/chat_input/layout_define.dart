import 'package:flutter/material.dart';

class DesktopAIPromptSizes {
  static const promptFrameRadius = BorderRadius.all(Radius.circular(8));

  static const attachedFilesBarPadding =
      EdgeInsets.only(top: 8, left: 8, right: 8);
  static const attachedFilesPreviewHeight = 48.0;
  static const attachedFilesPreviewSpacing = 12.0;

  static const textFieldMinHeight = 36.0;
  static const textFieldContentPadding =
      EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 4.0);

  static const actionBarHeight = 28.0;
  static const actionBarButtonSize = 24.0;
  static const actionBarIconSize = 16.0;
  static const actionBarButtonSpacing = 4.0;
  static const sendButtonSize = 20.0;
}

class MobileAIPromptSizes {
  static const promptFrameRadius =
      BorderRadius.vertical(top: Radius.circular(8));

  static const attachedFilesBarHeight = 68.0;
  static const attachedFilesBarPadding =
      EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 4);
  static const attachedFilesPreviewHeight = 56.0;
  static const attachedFilesPreviewSpacing = 8.0;

  static const textFieldMinHeight = 48.0;
  static const textFieldContentPadding = EdgeInsets.all(8.0);

  static const mentionIconSize = 20.0;
  static const sendButtonSize = 32.0;
}

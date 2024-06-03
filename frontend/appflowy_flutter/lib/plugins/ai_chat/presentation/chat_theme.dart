import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

// For internal usage only. Use values from theme itself.

/// See [ChatTheme.userAvatarNameColors].
const colors = [
  Color(0xffff6767),
  Color(0xff66e0da),
  Color(0xfff5a2d9),
  Color(0xfff0c722),
  Color(0xff6a85e5),
  Color(0xfffd9a6f),
  Color(0xff92db6e),
  Color(0xff73b8e5),
  Color(0xfffd7590),
  Color(0xffc78ae5),
];

/// Dark.
const dark = Color(0xff1f1c38);

/// Error.
const error = Color(0xffff6767);

/// N0.
const neutral0 = Color(0xff1d1c21);

/// N1.
const neutral1 = Color(0xff615e6e);

/// N2.
const neutral2 = Color(0xff9e9cab);

/// N7.
const neutral7 = Color(0xffffffff);

/// N7 with opacity.
const neutral7WithOpacity = Color(0x80ffffff);

/// Primary.
const primary = Color(0xff6f61e8);

/// Secondary.
const secondary = Color(0xfff5f5f7);

/// Secondary dark.
const secondaryDark = Color(0xff2b2250);

/// Default chat theme which extends [ChatTheme].
@immutable
class AFDefaultChatTheme extends ChatTheme {
  /// Creates a default chat theme. Use this constructor if you want to
  /// override only a couple of properties, otherwise create a new class
  /// which extends [ChatTheme].
  const AFDefaultChatTheme({
    super.attachmentButtonIcon,
    super.attachmentButtonMargin,
    super.backgroundColor = neutral7,
    super.bubbleMargin,
    super.dateDividerMargin = const EdgeInsets.only(
      bottom: 32,
      top: 16,
    ),
    super.dateDividerTextStyle = const TextStyle(
      color: neutral2,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.deliveredIcon,
    super.documentIcon,
    super.emptyChatPlaceholderTextStyle = const TextStyle(
      color: neutral2,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.errorColor = error,
    super.errorIcon,
    super.inputBackgroundColor = neutral0,
    super.inputSurfaceTintColor = neutral0,
    super.inputElevation = 0,
    super.inputBorderRadius = const BorderRadius.vertical(
      top: Radius.circular(20),
    ),
    super.inputContainerDecoration,
    super.inputMargin = EdgeInsets.zero,
    super.inputPadding = const EdgeInsets.fromLTRB(14, 20, 14, 20),
    super.inputTextColor = neutral7,
    super.inputTextCursorColor,
    super.inputTextDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isCollapsed: true,
    ),
    super.inputTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.messageBorderRadius = 20,
    super.messageInsetsHorizontal = 0,
    super.messageInsetsVertical = 0,
    super.messageMaxWidth = 1000,
    super.primaryColor = primary,
    super.receivedEmojiMessageTextStyle = const TextStyle(fontSize: 40),
    super.receivedMessageBodyBoldTextStyle,
    super.receivedMessageBodyCodeTextStyle,
    super.receivedMessageBodyLinkTextStyle,
    super.receivedMessageBodyTextStyle = const TextStyle(
      color: neutral0,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.receivedMessageCaptionTextStyle = const TextStyle(
      color: neutral2,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
    ),
    super.receivedMessageDocumentIconColor = primary,
    super.receivedMessageLinkDescriptionTextStyle = const TextStyle(
      color: neutral0,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.428,
    ),
    super.receivedMessageLinkTitleTextStyle = const TextStyle(
      color: neutral0,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.375,
    ),
    super.secondaryColor = secondary,
    super.seenIcon,
    super.sendButtonIcon,
    super.sendButtonMargin,
    super.sendingIcon,
    super.sentEmojiMessageTextStyle = const TextStyle(fontSize: 40),
    super.sentMessageBodyBoldTextStyle,
    super.sentMessageBodyCodeTextStyle,
    super.sentMessageBodyLinkTextStyle,
    super.sentMessageBodyTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.sentMessageCaptionTextStyle = const TextStyle(
      color: neutral7WithOpacity,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
    ),
    super.sentMessageDocumentIconColor = neutral7,
    super.sentMessageLinkDescriptionTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.428,
    ),
    super.sentMessageLinkTitleTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.375,
    ),
    super.statusIconPadding = const EdgeInsets.symmetric(horizontal: 4),
    super.systemMessageTheme = const SystemMessageTheme(
      margin: EdgeInsets.only(
        bottom: 24,
        top: 8,
        left: 8,
        right: 8,
      ),
      textStyle: TextStyle(
        color: neutral2,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.333,
      ),
    ),
    super.typingIndicatorTheme = const TypingIndicatorTheme(
      animatedCirclesColor: neutral1,
      animatedCircleSize: 5.0,
      bubbleBorder: BorderRadius.all(Radius.circular(27.0)),
      bubbleColor: neutral7,
      countAvatarColor: primary,
      countTextColor: secondary,
      multipleUserTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: neutral2,
      ),
    ),
    super.unreadHeaderTheme = const UnreadHeaderTheme(
      color: secondary,
      textStyle: TextStyle(
        color: neutral2,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.333,
      ),
    ),
    super.userAvatarImageBackgroundColor = Colors.transparent,
    super.userAvatarNameColors = colors,
    super.userAvatarTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.userNameTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.highlightMessageColor,
  });
}

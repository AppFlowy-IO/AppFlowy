import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_loading.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart'
    show regexEmail, regexLink;
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatTextMessageWidget extends StatefulWidget {
  const ChatTextMessageWidget({
    super.key,
    required this.user,
    required this.messageUserId,
    required this.text,
    this.options = const TextMessageOptions(),
  });

  final User user;
  final String messageUserId;
  final dynamic text;

  /// Customization options for the [ChatTextMessageWidget].
  final TextMessageOptions options;

  @override
  ChatTextMessageWidgetState createState() => ChatTextMessageWidgetState();
}

class ChatTextMessageWidgetState extends State<ChatTextMessageWidget> {
  StreamSubscription<String>? _subscription;
  String _currentText = "";

  @override
  void initState() {
    super.initState();
    if (widget.text is String) {
      _currentText = widget.text as String;
    } else if (widget.text is AnswerStream) {
      _subscribeToStream();
    }
  }

  @override
  void didUpdateWidget(ChatTextMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _unsubscribeFromStream();
      _subscribeToStream();
    }
  }

  @override
  void dispose() {
    _unsubscribeFromStream();
    super.dispose();
  }

  void _subscribeToStream() {
    if (widget.text is AnswerStream) {
      final stream = widget.text as AnswerStream;
      _subscription?.cancel();
      _subscription = stream.listen((data) {
        setState(() {
          _currentText = _currentText + data;
        });
      });
    }
  }

  void _unsubscribeFromStream() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentText.isEmpty) {
      return const ChatAILoading();
    } else {
      return _textWidgetBuilder(widget.user, context, _currentText);
    }
  }

  Widget _textWidgetBuilder(
    User user,
    BuildContext context,
    String text,
  ) {
    final bodyLinkTextStyle = user.id == widget.messageUserId
        ? const TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          )
        : const TextStyle(
            color: Colors.lightBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          );
    final bodyTextStyle = user.id == widget.messageUserId
        ? TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          )
        : TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          );
    final boldTextStyle = user.id == widget.messageUserId
        ? TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          )
        : TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          );
    final codeTextStyle = user.id == widget.messageUserId
        ? TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          )
        : TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextMessageText(
          bodyLinkTextStyle: bodyLinkTextStyle,
          bodyTextStyle: bodyTextStyle,
          boldTextStyle: boldTextStyle,
          codeTextStyle: codeTextStyle,
          options: widget.options,
          text: text,
        ),
      ],
    );
  }
}

/// Widget to reuse the markdown capabilities, e.g., for previews.
class TextMessageText extends StatelessWidget {
  const TextMessageText({
    super.key,
    this.bodyLinkTextStyle,
    required this.bodyTextStyle,
    this.boldTextStyle,
    this.codeTextStyle,
    this.maxLines,
    this.options = const TextMessageOptions(),
    this.overflow = TextOverflow.clip,
    required this.text,
  });

  /// Style to apply to anything that matches a link.
  final TextStyle? bodyLinkTextStyle;

  /// Regular style to use for any unmatched text. Also used as basis for the fallback options.
  final TextStyle bodyTextStyle;

  /// Style to apply to anything that matches bold markdown.
  final TextStyle? boldTextStyle;

  /// Style to apply to anything that matches code markdown.
  final TextStyle? codeTextStyle;

  /// See [ParsedText.maxLines].
  final int? maxLines;

  /// See [ChatTextMessageWidget.options].
  final TextMessageOptions options;

  /// See [ParsedText.overflow].
  final TextOverflow overflow;

  /// Text that is shown as markdown.
  final String text;

  @override
  Widget build(BuildContext context) => ParsedText(
        parse: [
          ...options.matchers,
          mailToMatcher(
            style: bodyLinkTextStyle ??
                bodyTextStyle.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
          urlMatcher(
            onLinkPressed: options.onLinkPressed,
            style: bodyLinkTextStyle ??
                bodyTextStyle.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
          boldMatcher(
            style: boldTextStyle ??
                bodyTextStyle.merge(PatternStyle.bold.textStyle),
          ),
          italicMatcher(
            style: bodyTextStyle.merge(PatternStyle.italic.textStyle),
          ),
          lineThroughMatcher(
            style: bodyTextStyle.merge(PatternStyle.lineThrough.textStyle),
          ),
          codeMatcher(
            style: codeTextStyle ??
                bodyTextStyle.merge(PatternStyle.code.textStyle),
          ),
        ],
        maxLines: maxLines,
        overflow: overflow,
        regexOptions: const RegexOptions(multiLine: true, dotAll: true),
        selectable: options.isTextSelectable,
        style: bodyTextStyle,
        text: text,
        textWidthBasis: TextWidthBasis.longestLine,
      );
}

@immutable
class TextMessageOptions {
  const TextMessageOptions({
    this.isTextSelectable = true,
    this.onLinkPressed,
    this.openOnPreviewImageTap = false,
    this.openOnPreviewTitleTap = false,
    this.matchers = const [],
  });

  /// Whether user can tap and hold to select a text content.
  final bool isTextSelectable;

  /// Custom link press handler.
  final void Function(String)? onLinkPressed;

  final bool openOnPreviewImageTap;

  final bool openOnPreviewTitleTap;

  /// Additional matchers to parse the text.
  final List<MatchText> matchers;
}

MatchText mailToMatcher({
  final TextStyle? style,
}) =>
    MatchText(
      onTap: (mail) async {
        final url = Uri(scheme: 'mailto', path: mail);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
      pattern: regexEmail,
      style: style,
    );

MatchText urlMatcher({
  final TextStyle? style,
  final Function(String url)? onLinkPressed,
}) =>
    MatchText(
      onTap: (urlText) async {
        final protocolIdentifierRegex = RegExp(
          r'^((http|ftp|https):\/\/)',
          caseSensitive: false,
        );
        if (!urlText.startsWith(protocolIdentifierRegex)) {
          urlText = 'https://$urlText';
        }
        if (onLinkPressed != null) {
          onLinkPressed(urlText);
        } else {
          final url = Uri.tryParse(urlText);
          if (url != null && await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
          }
        }
      },
      pattern: regexLink,
      style: style,
    );

MatchText _patternStyleMatcher({
  required final PatternStyle patternStyle,
  final TextStyle? style,
}) =>
    MatchText(
      pattern: patternStyle.pattern,
      style: style,
      renderText: ({required String str, required String pattern}) => {
        'display': str.replaceAll(
          patternStyle.from,
          patternStyle.replace,
        ),
      },
    );

MatchText boldMatcher({
  final TextStyle? style,
}) =>
    _patternStyleMatcher(
      patternStyle: PatternStyle.bold,
      style: style,
    );

MatchText italicMatcher({
  final TextStyle? style,
}) =>
    _patternStyleMatcher(
      patternStyle: PatternStyle.italic,
      style: style,
    );

MatchText lineThroughMatcher({
  final TextStyle? style,
}) =>
    _patternStyleMatcher(
      patternStyle: PatternStyle.lineThrough,
      style: style,
    );

MatchText codeMatcher({
  final TextStyle? style,
}) =>
    _patternStyleMatcher(
      patternStyle: PatternStyle.code,
      style: style,
    );

class PatternStyle {
  PatternStyle(this.from, this.regExp, this.replace, this.textStyle);

  final Pattern from;
  final RegExp regExp;
  final String replace;
  final TextStyle textStyle;

  String get pattern => regExp.pattern;

  static PatternStyle get bold => PatternStyle(
        '*',
        RegExp('\\*[^\\*]+\\*'),
        '',
        const TextStyle(fontWeight: FontWeight.bold),
      );

  static PatternStyle get code => PatternStyle(
        '`',
        RegExp('`[^`]+`'),
        '',
        TextStyle(
          fontFamily: defaultTargetPlatform == TargetPlatform.iOS
              ? 'Courier'
              : 'monospace',
        ),
      );

  static PatternStyle get italic => PatternStyle(
        '_',
        RegExp('_[^_]+_'),
        '',
        const TextStyle(fontStyle: FontStyle.italic),
      );

  static PatternStyle get lineThrough => PatternStyle(
        '~',
        RegExp('~[^~]+~'),
        '',
        const TextStyle(decoration: TextDecoration.lineThrough),
      );
}

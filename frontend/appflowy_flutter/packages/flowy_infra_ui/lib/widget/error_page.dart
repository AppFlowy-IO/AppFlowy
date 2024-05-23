import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class FlowyErrorPage extends StatelessWidget {
  factory FlowyErrorPage.error(
    Error e, {
    required String howToFix,
    Key? key,
    List<Widget>? actions,
  }) =>
      FlowyErrorPage._(
        e.toString(),
        stackTrace: e.stackTrace?.toString(),
        howToFix: howToFix,
        key: key,
        actions: actions,
      );

  factory FlowyErrorPage.message(
    String message, {
    required String howToFix,
    String? stackTrace,
    Key? key,
    List<Widget>? actions,
  }) =>
      FlowyErrorPage._(
        message,
        key: key,
        stackTrace: stackTrace,
        howToFix: howToFix,
        actions: actions,
      );

  factory FlowyErrorPage.exception(
    Exception e, {
    required String howToFix,
    String? stackTrace,
    Key? key,
    List<Widget>? actions,
  }) =>
      FlowyErrorPage._(
        e.toString(),
        stackTrace: stackTrace,
        key: key,
        howToFix: howToFix,
        actions: actions,
      );

  const FlowyErrorPage._(
    this.message, {
    required this.howToFix,
    this.stackTrace,
    super.key,
    this.actions,
  });

  static const _titleFontSize = 24.0;
  static const _titleToMessagePadding = 8.0;

  final List<Widget>? actions;
  final String howToFix;
  final String message;
  final String? stackTrace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlowyText.medium(
            "AppFlowy Error",
            fontSize: _titleFontSize,
          ),
          const SizedBox(
            height: _titleToMessagePadding,
          ),
          FlowyText.semibold(
            message,
            maxLines: 10,
          ),
          const SizedBox(
            height: _titleToMessagePadding,
          ),
          FlowyText.regular(
            howToFix,
            maxLines: 10,
          ),
          const SizedBox(
            height: _titleToMessagePadding,
          ),
          const GitHubRedirectButton(),
          const SizedBox(
            height: _titleToMessagePadding,
          ),
          if (stackTrace != null) StackTracePreview(stackTrace!),
          if (actions != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
        ],
      ),
    );
  }
}

class StackTracePreview extends StatelessWidget {
  const StackTracePreview(
    this.stackTrace, {
    super.key,
  });

  final String stackTrace;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 350,
        maxWidth: 450,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: FlowyText.semibold(
                  "Stack Trace",
                ),
              ),
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  child: Text(
                    stackTrace,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FlowyButton(
                  hoverColor: AFThemeExtension.of(context).onBackground,
                  text: const FlowyText(
                    "Copy",
                  ),
                  useIntrinsicWidth: true,
                  onTap: () => Clipboard.setData(
                    ClipboardData(text: stackTrace),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GitHubRedirectButton extends StatelessWidget {
  const GitHubRedirectButton({super.key});

  static const _height = 32.0;

  Uri get _gitHubNewBugUri => Uri(
        scheme: 'https',
        host: 'github.com',
        path: '/AppFlowy-IO/AppFlowy/issues/new',
        query:
            'assignees=&labels=&projects=&template=bug_report.yaml&title=%5BBug%5D+',
      );

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      leftIconSize: const Size.square(_height),
      text: const FlowyText(
        "AppFlowy",
      ),
      useIntrinsicWidth: true,
      leftIcon: const Padding(
        padding: EdgeInsets.all(4.0),
        child: FlowySvg(FlowySvgData('login/github-mark')),
      ),
      onTap: () async {
        if (await canLaunchUrl(_gitHubNewBugUri)) {
          await launchUrl(_gitHubNewBugUri);
        }
      },
    );
  }
}

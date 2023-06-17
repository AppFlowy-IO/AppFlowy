import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class FlowyErrorPage extends StatelessWidget {
  factory FlowyErrorPage.error(
    Error e, {
    required String howToFix,
    Key? key,
  }) =>
      FlowyErrorPage._(
        e.toString(),
        stackTrace: e.stackTrace?.toString(),
        howToFix: howToFix,
        key: key,
      );

  factory FlowyErrorPage.message(
    String message, {
    required String howToFix,
    String? stackTrace,
    Key? key,
  }) =>
      FlowyErrorPage._(
        message,
        key: key,
        stackTrace: stackTrace,
        howToFix: howToFix,
      );

  factory FlowyErrorPage.exception(
    Exception e, {
    required String howToFix,
    String? stackTrace,
    Key? key,
  }) =>
      FlowyErrorPage._(
        e.toString(),
        stackTrace: stackTrace,
        key: key,
        howToFix: howToFix,
      );

  const FlowyErrorPage._(
    this.message, {
    required this.howToFix,
    this.stackTrace,
    super.key,
  });

  static const _titleFontSize = 24.0;
  static const _titleToMessagePadding = 8.0;

  final String message;
  final String? stackTrace;
  final String howToFix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
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
          ),
          const SizedBox(
            height: _titleToMessagePadding,
          ),
          FlowyText.regular(
            howToFix,
          ),
          const SizedBox(
            height: _titleToMessagePadding,
          ),
          const GitHubRedirectButton(),
          const SizedBox(
            height: _titleToMessagePadding,
          ),
          if (stackTrace != null) StackTracePreview(stackTrace!),
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
                  hoverColor: Theme.of(context).colorScheme.onBackground,
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
        leftIcon: Padding(
          padding: const EdgeInsets.all(4.0),
          child: svgWidget('login/github-mark'),
        ),
        onTap: () => canLaunchUrl(_gitHubNewBugUri).then(
              (result) => result ? launchUrl(_gitHubNewBugUri) : null,
            ));
  }
}

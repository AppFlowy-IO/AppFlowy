import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/rust_sdk.dart';
import 'package:appflowy/workspace/application/update_checker/update_checker_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 30,
      height: 30,
      child: BubbleActionList(),
    );
  }
}

class BubbleActionList extends StatefulWidget {
  const BubbleActionList({super.key});

  @override
  State<BubbleActionList> createState() => _BubbleActionListState();
}

class _BubbleActionListState extends State<BubbleActionList> {
  bool isOpen = false;

  Color get fontColor => isOpen
      ? Theme.of(context).colorScheme.onPrimary
      : Theme.of(context).colorScheme.tertiary;

  Color get fillColor => isOpen
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.tertiaryContainer;

  void toggle() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<PopoverAction> actions = [
      ...BubbleAction.values.map((action) => BubbleActionWrapper(action)),
      FlowyVersionDescription(),
      FlowyUpdateStatus(),
    ];

    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.topWithRightAligned,
      actions: actions,
      offset: const Offset(0, -8),
      constraints: const BoxConstraints(
        minWidth: 170,
        maxWidth: 225,
        maxHeight: 300,
      ),
      buildChild: (controller) {
        return FlowyTextButton(
          '?',
          tooltip: LocaleKeys.questionBubble_help.tr(),
          fontWeight: FontWeight.w600,
          fontColor: fontColor,
          fillColor: fillColor,
          hoverColor: Theme.of(context).colorScheme.primary,
          mainAxisAlignment: MainAxisAlignment.center,
          radius: Corners.s10Border,
          onPressed: () {
            toggle();
            controller.show();
          },
        );
      },
      onClosed: toggle,
      onSelected: (action, controller) {
        if (action is BubbleActionWrapper) {
          switch (action.inner) {
            case BubbleAction.whatsNews:
              _launchURL("https://www.appflowy.io/what-is-new");
              break;
            case BubbleAction.help:
              _launchURL("https://discord.gg/9Q2xaN37tV");
              break;
            case BubbleAction.debug:
              _DebugToast().show();
              break;
            case BubbleAction.shortcuts:
              _launchURL(
                "https://appflowy.gitbook.io/docs/essential-documentation/shortcuts",
              );
              break;
            case BubbleAction.markdown:
              _launchURL(
                "https://appflowy.gitbook.io/docs/essential-documentation/markdown",
              );
              break;
            case BubbleAction.github:
              _launchURL(
                'https://github.com/AppFlowy-IO/AppFlowy/issues/new/choose',
              );
              break;
          }
        }

        controller.close();
      },
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class _DebugToast {
  void show() async {
    String debugInfo = "";
    debugInfo += await _getDeviceInfo();
    debugInfo += await _getDocumentPath();
    await Clipboard.setData(ClipboardData(text: debugInfo));

    showMessageToast(LocaleKeys.questionBubble_debug_success.tr());
  }

  Future<String> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = await deviceInfoPlugin.deviceInfo;

    return deviceInfo.data.entries
        .fold('', (prev, el) => "$prev${el.key}: ${el.value}\n");
  }

  Future<String> _getDocumentPath() async {
    return appFlowyApplicationDataDirectory().then((directory) {
      final path = directory.path.toString();
      return "Document: $path\n";
    });
  }
}

class FlowyVersionDescription extends CustomActionCell {
  @override
  Widget buildWithContext(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return FlowyText(
              "Error: ${snapshot.error}",
              color: Theme.of(context).disabledColor,
            );
          }

          final PackageInfo packageInfo = snapshot.data;
          final String appName = packageInfo.appName;
          final String version = packageInfo.version;

          return SizedBox(
            height: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                  thickness: 1.0,
                ),
                const VSpace(6),
                FlowyText(
                  "$appName $version",
                  color: Theme.of(context).hintColor,
                ),
              ],
            ).padding(
              horizontal: ActionListSizes.itemHPadding,
            ),
          );
        } else {
          return const SizedBox(height: 30);
        }
      },
    );
  }
}

class FlowyUpdateStatus extends CustomActionCell {
  @override
  Widget buildWithContext(BuildContext context) {
    return BlocProvider.value(
      value: getIt<VersionCheckerBloc>(),
      child: BlocBuilder<VersionCheckerBloc, VersionCheckerState>(
        builder: (context, state) {
          return SizedBox(
            height: 23,
            child: Row(
              children: [
                FlowyText(
                  state.maybeWhen(
                    orElse: () =>
                        LocaleKeys.questionBubble_updateStatus_checking.tr(),
                    upToDate: () =>
                        LocaleKeys.questionBubble_updateStatus_upToDate.tr(),
                    updateAvailable: (v) => LocaleKeys
                        .questionBubble_updateStatus_updateAvailable
                        .tr(args: [v]),
                  ),
                  maxLines: 2,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ).padding(
              horizontal: ActionListSizes.itemHPadding,
            ),
          );
        },
      ),
    );
  }
}

enum BubbleAction { whatsNews, help, debug, shortcuts, markdown, github }

class BubbleActionWrapper extends ActionCell {
  BubbleActionWrapper(this.inner);

  final BubbleAction inner;

  @override
  Widget? leftIcon(Color iconColor) => inner.emoji;

  @override
  String get name => inner.name;
}

extension QuestionBubbleExtension on BubbleAction {
  String get name {
    switch (this) {
      case BubbleAction.whatsNews:
        return LocaleKeys.questionBubble_whatsNew.tr();
      case BubbleAction.help:
        return LocaleKeys.questionBubble_help.tr();
      case BubbleAction.debug:
        return LocaleKeys.questionBubble_debug_name.tr();
      case BubbleAction.shortcuts:
        return LocaleKeys.questionBubble_shortcuts.tr();
      case BubbleAction.markdown:
        return LocaleKeys.questionBubble_markdown.tr();
      case BubbleAction.github:
        return LocaleKeys.questionBubble_feedback.tr();
    }
  }

  Widget get emoji {
    switch (this) {
      case BubbleAction.whatsNews:
        return const FlowyText.regular('🆕');
      case BubbleAction.help:
        return const FlowyText.regular('👥');
      case BubbleAction.debug:
        return const FlowyText.regular('🐛');
      case BubbleAction.shortcuts:
        return const FlowyText.regular('📋');
      case BubbleAction.markdown:
        return const FlowyText.regular('✨');
      case BubbleAction.github:
        return const Padding(
          padding: EdgeInsets.all(3.0),
          child: FlowySvg(
            FlowySvgs.archive_m,
            size: Size.square(12),
          ),
        );
    }
  }
}

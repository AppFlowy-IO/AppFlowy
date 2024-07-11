import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/env/env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/startup/tasks/rust_sdk.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 36.0,
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
    final List<PopoverAction> actions = [];
    actions.addAll(
      BubbleAction.values.map((action) => BubbleActionWrapper(action)),
    );
    actions.add(FlowyVersionDescription());

    final (color, borderColor, shadowColor, iconColor) =
        Theme.of(context).isLightMode
            ? (
                Colors.white,
                const Color(0x2D454849),
                const Color(0x14000000),
                Colors.black,
              )
            : (
                const Color(0xFF242B37),
                const Color(0x2DFFFFFF),
                const Color(0x14000000),
                Colors.white,
              );

    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.topWithRightAligned,
      actions: actions,
      offset: const Offset(0, -8),
      buildChild: (controller) {
        return FlowyTooltip(
          message: LocaleKeys.questionBubble_help.tr(),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: ShapeDecoration(
                  color: color,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 0.50, color: borderColor),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  shadows: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FlowySvg(
                  FlowySvgs.help_center_s,
                  color: iconColor,
                ),
              ),
              onTap: () => controller.show(),
            ),
          ),
        );
      },
      onClosed: toggle,
      onSelected: (action, controller) {
        if (action is BubbleActionWrapper) {
          switch (action.inner) {
            case BubbleAction.whatsNews:
              afLaunchUrlString("https://www.appflowy.io/what-is-new");
              break;
            case BubbleAction.help:
              afLaunchUrlString("https://discord.gg/9Q2xaN37tV");
              break;
            case BubbleAction.debug:
              _DebugToast().show();
              break;
            case BubbleAction.shortcuts:
              afLaunchUrlString(
                "https://docs.appflowy.io/docs/appflowy/product/shortcuts",
              );
              break;
            case BubbleAction.markdown:
              afLaunchUrlString(
                "https://docs.appflowy.io/docs/appflowy/product/markdown",
              );
              break;
            case BubbleAction.github:
              afLaunchUrlString(
                'https://github.com/AppFlowy-IO/AppFlowy/issues/new/choose',
              );
              break;
          }
        }

        controller.close();
      },
    );
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
  Widget buildWithContext(BuildContext context, PopoverController controller) {
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () {
                    if (Env.internalBuild != '1' && !kDebugMode) {
                      return;
                    }
                    enableDocumentInternalLog = !enableDocumentInternalLog;
                    showToastNotification(
                      context,
                      message: enableDocumentInternalLog
                          ? 'Enabled Internal Log'
                          : 'Disabled Internal Log',
                    );
                  },
                  child: FlowyText(
                    '$appName $version',
                    color: Theme.of(context).hintColor,
                  ),
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

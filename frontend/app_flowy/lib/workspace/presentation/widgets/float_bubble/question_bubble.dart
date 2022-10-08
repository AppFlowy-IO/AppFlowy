import 'package:app_flowy/startup/tasks/rust_sdk.dart';
import 'package:app_flowy/workspace/presentation/home/toast.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:device_info_plus/device_info_plus.dart';

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 30,
      height: 30,
      child: BubbleActionList(),
    );
  }
}

class BubbleActionList extends StatelessWidget {
  const BubbleActionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    final List<PopoverAction> actions = [];
    actions.addAll(
      BubbleAction.values.map((action) => BubbleActionWrapper(action)),
    );
    actions.add(FlowyVersionDescription());

    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.topWithRightAligned,
      actions: actions,
      withChild: (controller) {
        return FlowyTextButton(
          '?',
          tooltip: LocaleKeys.questionBubble_help.tr(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fillColor: theme.selector,
          mainAxisAlignment: MainAxisAlignment.center,
          radius: BorderRadius.circular(10),
          onPressed: () => controller.show(),
        );
      },
      onSelected: (action, controller) {
        if (action is BubbleActionWrapper) {
          switch (action.inner) {
            case BubbleAction.whatsNews:
              _launchURL("https://www.appflowy.io/whatsnew");
              break;
            case BubbleAction.help:
              _launchURL("https://discord.gg/9Q2xaN37tV");
              break;
            case BubbleAction.debug:
              _DebugToast().show();
              break;
          }
        }

        controller.close();
      },
    );
  }

  _launchURL(String url) async {
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
    var debugInfo = "";
    debugInfo += await _getDeviceInfo();
    debugInfo += await _getDocumentPath();
    Clipboard.setData(ClipboardData(text: debugInfo));

    showMessageToast(LocaleKeys.questionBubble_debug_success.tr());
  }

  Future<String> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = deviceInfoPlugin.deviceInfo;

    return deviceInfo.then((info) {
      var debugText = "";
      info.toMap().forEach((key, value) {
        debugText = "$debugText$key: $value\n";
      });
      return debugText;
    });
  }

  Future<String> _getDocumentPath() async {
    return appFlowyDocumentDirectory().then((directory) {
      final path = directory.path.toString();
      return "Document: $path\n";
    });
  }
}

class FlowyVersionDescription extends CustomActionCell {
  @override
  Widget buildWithContext(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return FlowyText("Error: ${snapshot.error}",
                fontSize: 12, color: theme.shader4);
          }

          PackageInfo packageInfo = snapshot.data;
          String appName = packageInfo.appName;
          String version = packageInfo.version;
          String buildNumber = packageInfo.buildNumber;

          return SizedBox(
            height: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: theme.shader6, thickness: 1.0),
                const VSpace(6),
                FlowyText(
                  "$appName $version.$buildNumber",
                  fontSize: 12,
                  color: theme.shader4,
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

enum BubbleAction { whatsNews, help, debug }

class BubbleActionWrapper extends ActionCell {
  final BubbleAction inner;

  BubbleActionWrapper(this.inner);
  @override
  Widget? icon(Color iconColor) => inner.emoji;

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
    }
  }

  Widget get emoji {
    switch (this) {
      case BubbleAction.whatsNews:
        return const Text('⭐️', style: TextStyle(fontSize: 12));
      case BubbleAction.help:
        return const Text('👥', style: TextStyle(fontSize: 12));
      case BubbleAction.debug:
        return const Text('🐛', style: TextStyle(fontSize: 12));
    }
  }
}

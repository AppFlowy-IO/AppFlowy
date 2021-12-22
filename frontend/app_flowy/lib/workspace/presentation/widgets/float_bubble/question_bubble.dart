import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:styled_widget/styled_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:app_flowy/workspace/presentation/stack_page/home_stack.dart';

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      width: 30,
      height: 30,
      child: FlowyTextButton(
        '?',
        tooltip: LocaleKeys.questionBubble_help.tr(),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fillColor: theme.selector,
        mainAxisAlignment: MainAxisAlignment.center,
        radius: BorderRadius.circular(10),
        onPressed: () {
          final actionList = QuestionBubbleActionSheet(onSelected: (result) {
            result.fold(() {}, (action) {
              switch (action) {
                case BubbleAction.whatsNews:
                  _launchURL("https://www.appflowy.io/whatsnew");
                  break;
                case BubbleAction.help:
                  _launchURL("https://discord.gg/9Q2xaN37tV");
                  break;
                case BubbleAction.debug:
                  final deviceInfoPlugin = DeviceInfoPlugin();

                  final dynamic deviceInfo;
                  if(Platform.isLinux) {
                    deviceInfo = deviceInfoPlugin.linuxInfo;
                  } else if(Platform.isMacOS) {
                    deviceInfo = deviceInfoPlugin.macOsInfo;
                  } else if(Platform.isWindows) {
                    deviceInfo = deviceInfoPlugin.windowsInfo;
                  } else {
                    throw Exception('Unsupported platform when getting debug info');
                  }
                  
                  deviceInfo.then((info) {
                    Clipboard.setData(ClipboardData( text: info.toMap().toString() ));

                    Widget toast = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.0),
                        color: theme.main1,
                      ),
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                          Icon(Icons.check),
                          SizedBox(
                          width: 12.0,
                          ),
                          Text("Copied debug info to clipboard!"),
                        ],
                      ),
                    );

                    fToast.showToast(
                        child: toast,
                        gravity: ToastGravity.BOTTOM,
                        toastDuration: const Duration(seconds: 3),
                    );
                  });

                  break;
              }
            });
          });
          actionList.show(
            context,
            context,
            anchorDirection: AnchorDirection.topWithRightAligned,
            anchorOffset: const Offset(0, -10),
          );
        },
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class QuestionBubbleActionSheet with ActionList<BubbleActionWrapper> implements FlowyOverlayDelegate {
  final Function(dartz.Option<BubbleAction>) onSelected;
  final _items = BubbleAction.values.map((action) => BubbleActionWrapper(action)).toList();

  QuestionBubbleActionSheet({
    required this.onSelected,
  });

  @override
  double get maxWidth => 170;

  @override
  double get itemHeight => 22;

  @override
  List<BubbleActionWrapper> get items => _items;

  @override
  void Function(dartz.Option<BubbleActionWrapper> p1) get selectCallback => (result) {
        result.fold(
          () => onSelected(dartz.none()),
          (wrapper) => onSelected(
            dartz.some(wrapper.inner),
          ),
        );
      };

  @override
  FlowyOverlayDelegate? get delegate => this;

  @override
  void didRemove() {
    onSelected(dartz.none());
  }

  @override
  ListOverlayFooter? get footer => ListOverlayFooter(
        widget: const FlowyVersionDescription(),
        height: 30,
        padding: const EdgeInsets.only(top: 6),
      );
}

class FlowyVersionDescription extends StatelessWidget {
  const FlowyVersionDescription({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return FlowyText("Error: ${snapshot.error}", fontSize: 12, color: theme.shader4);
          }

          PackageInfo packageInfo = snapshot.data;
          String appName = packageInfo.appName;
          String version = packageInfo.version;
          String buildNumber = packageInfo.buildNumber;

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 1, color: theme.shader6, thickness: 1.0),
              const VSpace(6),
              FlowyText("$appName $version.$buildNumber", fontSize: 12, color: theme.shader4),
            ],
          ).padding(
            horizontal: ActionListSizes.itemHPadding + ActionListSizes.padding,
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

enum BubbleAction {
  whatsNews,
  help,
  debug
}

class BubbleActionWrapper extends ActionItem {
  final BubbleAction inner;

  BubbleActionWrapper(this.inner);
  @override
  Widget? get icon => inner.emoji;

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
        return LocaleKeys.questionBubble_debug.tr();
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

import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:styled_widget/styled_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
        tooltip: BubbleAction.values.map((action) => action.name).toList().join(','),
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
                  // TODO: annie replace the URL with real ones
                  _launchURL("https://www.appflowy.io/whatsnew");
                  break;
                case BubbleAction.help:
                  // TODO: annie replace the URL with real ones
                  _launchURL("https://discord.gg/9Q2xaN37tV");
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
        return "What's new?";
      case BubbleAction.help:
        return "Help & Support";
    }
  }

  Widget get emoji {
    switch (this) {
      case BubbleAction.whatsNews:
        return const Text('⭐️', style: TextStyle(fontSize: 12));
      case BubbleAction.help:
        return const Text('👥', style: TextStyle(fontSize: 12));
    }
  }
}

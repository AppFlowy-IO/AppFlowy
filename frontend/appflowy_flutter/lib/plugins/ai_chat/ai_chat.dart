import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class AIChatPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return AIChatPagePlugin();
  }

  @override
  String get menuName => "AIChat";

  @override
  FlowySvgData get icon => FlowySvgs.ai_summary_s;

  @override
  PluginType get pluginType => PluginType.aiChat;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Chat;
}

class AIChatPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}

class AIChatPagePlugin extends Plugin {
  @override
  PluginWidgetBuilder get widgetBuilder => AIChatPagePluginWidgetBuilder();

  @override
  PluginId get id => "AIChatStack";

  @override
  PluginType get pluginType => PluginType.aiChat;
}

class AIChatPagePluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  @override
  Widget get leftBarItem => FlowyText.medium(LocaleKeys.blankPageTitle.tr());

  @override
  Widget tabBarItem(String pluginId) => leftBarItem;

  @override
  Widget buildWidget({PluginContext? context, required bool shrinkWrap}) =>
      const AIChatPage();

  @override
  List<NavigationItem> get navigationItems => [this];
}

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: SizedBox.shrink(),
        ),
      ),
    );
  }
}

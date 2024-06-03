import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class BlankPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return BlankPagePlugin();
  }

  @override
  String get menuName => "Blank";

  @override
  FlowySvgData get icon => const FlowySvgData('');

  @override
  PluginType get pluginType => PluginType.blank;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Document;
}

class BlankPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class BlankPagePlugin extends Plugin {
  @override
  PluginWidgetBuilder get widgetBuilder => BlankPagePluginWidgetBuilder();

  @override
  PluginId get id => "BlankStack";

  @override
  PluginType get pluginType => PluginType.blank;
}

class BlankPagePluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  @override
  Widget get leftBarItem => FlowyText.medium(LocaleKeys.blankPageTitle.tr());

  @override
  Widget tabBarItem(String pluginId) => leftBarItem;

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
  }) =>
      const BlankPage();

  @override
  List<NavigationItem> get navigationItems => [this];
}

class BlankPage extends StatefulWidget {
  const BlankPage({super.key});

  @override
  State<BlankPage> createState() => _BlankPageState();
}

class _BlankPageState extends State<BlankPage> {
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

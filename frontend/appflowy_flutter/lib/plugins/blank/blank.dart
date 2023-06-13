import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';

class BlankPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return BlankPagePlugin();
  }

  @override
  String get menuName => "Blank";

  @override
  String get menuIcon => "";

  @override
  PluginType get pluginType => PluginType.blank;
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
  Widget buildWidget({PluginContext? context}) => const BlankPage();

  @override
  List<NavigationItem> get navigationItems => [this];
}

class BlankPage extends StatefulWidget {
  const BlankPage({Key? key}) : super(key: key);

  @override
  State<BlankPage> createState() => _BlankPageState();
}

class _BlankPageState extends State<BlankPage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(),
        ),
      ),
    );
  }
}

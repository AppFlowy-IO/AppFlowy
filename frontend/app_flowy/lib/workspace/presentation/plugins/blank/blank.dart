import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugin/plugin.dart';

class BlankPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return BlankPagePlugin(pluginType: pluginType);
  }

  @override
  String get menuName => "Blank";

  @override
  PluginType get pluginType => DefaultPlugin.blank.type();
}

class BlankPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class BlankPagePlugin extends Plugin {
  final PluginType _pluginType;
  BlankPagePlugin({
    required PluginType pluginType,
  }) : _pluginType = pluginType;

  @override
  PluginDisplay get display => BlankPagePluginDisplay();

  @override
  PluginId get id => "BlankStack";

  @override
  PluginType get ty => _pluginType;
}

class BlankPagePluginDisplay extends PluginDisplay {
  @override
  Widget get leftBarItem => FlowyText.medium(LocaleKeys.blankPageTitle.tr(), fontSize: 12);

  @override
  Widget buildWidget() => const BlankPage();

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

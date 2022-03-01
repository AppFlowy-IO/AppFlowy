import 'package:app_flowy/startup/tasks/load_plugin.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';

class BlankPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return BlankPagePlugin(pluginType: pluginType);
  }

  @override
  String get name => "Blank";

  @override
  PluginType get pluginType => DefaultPlugin.blank.type();
}

class BlankPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class BlankPagePlugin implements Plugin {
  final PluginType _pluginType;
  BlankPagePlugin({
    required PluginType pluginType,
  }) : _pluginType = pluginType;

  @override
  void dispose() {}

  @override
  PluginDisplay get display => BlankPagePluginDisplay();

  @override
  String get pluginId => "BlankStack";

  @override
  PluginType get pluginType => _pluginType;
}

class BlankPagePluginDisplay extends PluginDisplay {
  @override
  Widget get leftBarItem => FlowyText.medium(LocaleKeys.blankPageTitle.tr(), fontSize: 12);

  @override
  Widget? get rightBarItem => null;

  @override
  Widget buildWidget() {
    return const BlankStackPage();
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}

class BlankStackPage extends StatefulWidget {
  const BlankStackPage({Key? key}) : super(key: key);

  @override
  State<BlankStackPage> createState() => _BlankStackPageState();
}

class _BlankStackPageState extends State<BlankStackPage> {
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

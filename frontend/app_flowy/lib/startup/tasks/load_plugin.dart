import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/doc/doc_stack_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/trash/trash_page.dart';

enum DefaultPluginEnum {
  blank,
  trash,
}

extension FlowyDefaultPluginExt on DefaultPluginEnum {
  String type() {
    switch (this) {
      case DefaultPluginEnum.blank:
        return "Blank";
      case DefaultPluginEnum.trash:
        return "Trash";
    }
  }
}

bool isDefaultPlugin(String pluginType) {
  return DefaultPluginEnum.values.map((e) => e.type()).contains(pluginType);
}

class PluginLoadTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    registerPlugin(builder: DocumentPluginBuilder());

    registerPlugin(builder: TrashPluginBuilder());

    registerPlugin(builder: BlankPluginBuilder());
  }
}

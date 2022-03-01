import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/doc/doc_stack_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/trash/trash_page.dart';

enum DefaultPlugin {
  quillEditor,
  blank,
  trash,
}

extension FlowyDefaultPluginExt on DefaultPlugin {
  int type() {
    switch (this) {
      case DefaultPlugin.quillEditor:
        return 0;
      case DefaultPlugin.blank:
        return 1;
      case DefaultPlugin.trash:
        return 2;
    }
  }
}

bool isDefaultPlugin(PluginType pluginType) {
  return DefaultPlugin.values.map((e) => e.type()).contains(pluginType);
}

class PluginLoadTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    registerPlugin(builder: BlankPluginBuilder());
    registerPlugin(builder: TrashPluginBuilder());
    registerPlugin(builder: DocumentPluginBuilder());
  }
}

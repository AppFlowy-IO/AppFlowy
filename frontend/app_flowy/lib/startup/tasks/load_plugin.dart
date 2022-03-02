import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/plugins/blank/blank.dart';
import 'package:app_flowy/workspace/presentation/plugins/doc/document.dart';
import 'package:app_flowy/workspace/presentation/plugins/trash/trash.dart';

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

class PluginLoadTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    registerPlugin(builder: BlankPluginBuilder(), config: BlankPluginConfig());
    registerPlugin(builder: TrashPluginBuilder(), config: TrashPluginConfig());
    registerPlugin(builder: DocumentPluginBuilder());
  }
}

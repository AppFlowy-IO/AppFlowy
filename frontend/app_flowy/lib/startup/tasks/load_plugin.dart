import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/blank/blank.dart';
import 'package:app_flowy/plugins/board/board.dart';
import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/plugins/grid/grid.dart';
import 'package:app_flowy/plugins/trash/trash.dart';

class PluginLoadTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    registerPlugin(builder: BlankPluginBuilder(), config: BlankPluginConfig());
    registerPlugin(builder: TrashPluginBuilder(), config: TrashPluginConfig());
    registerPlugin(builder: DocumentPluginBuilder());
    registerPlugin(builder: GridPluginBuilder(), config: GridPluginConfig());
    registerPlugin(builder: BoardPluginBuilder(), config: BoardPluginConfig());
  }
}

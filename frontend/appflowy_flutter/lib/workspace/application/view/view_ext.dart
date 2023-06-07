import 'package:appflowy/plugins/database_view/database_view.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:flowy_infra/image.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

enum FlowyPlugin {
  editor,
  kanban,
}

extension FlowyPluginExtension on FlowyPlugin {
  String displayName() {
    switch (this) {
      case FlowyPlugin.editor:
        return "Doc";
      case FlowyPlugin.kanban:
        return "Kanban";
      default:
        return "";
    }
  }

  bool enable() {
    switch (this) {
      case FlowyPlugin.editor:
        return true;
      case FlowyPlugin.kanban:
        return false;
      default:
        return false;
    }
  }
}

extension ViewExtension on ViewPB {
  Widget renderThumbnail({Color? iconColor}) {
    const String thumbnail = "file_icon";

    const Widget widget = FlowySvg(name: thumbnail);
    return widget;
  }

  PluginType get pluginType {
    switch (layout) {
      case ViewLayoutPB.Board:
        return PluginType.board;
      case ViewLayoutPB.Calendar:
        return PluginType.calendar;
      case ViewLayoutPB.Document:
        return PluginType.editor;
      case ViewLayoutPB.Grid:
        return PluginType.grid;
    }

    throw UnimplementedError;
  }

  Plugin plugin() {
    switch (layout) {
      case ViewLayoutPB.Board:
      case ViewLayoutPB.Calendar:
      case ViewLayoutPB.Grid:
        return DatabaseViewPlugin(view: this);
      case ViewLayoutPB.Document:
        return makePlugin(pluginType: pluginType, data: this);
    }
    throw UnimplementedError;
  }
}

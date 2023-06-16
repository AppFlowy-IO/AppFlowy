import 'package:appflowy/plugins/database_view/board/board.dart';
import 'package:appflowy/plugins/database_view/calendar/calendar.dart';
import 'package:appflowy/plugins/database_view/grid/grid.dart';
import 'package:appflowy/plugins/document/document.dart';
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

  Plugin plugin({bool listenOnViewChanged = false}) {
    switch (layout) {
      case ViewLayoutPB.Board:
        return BoardPlugin(
          view: this,
          pluginType: pluginType,
          listenOnViewChanged: listenOnViewChanged,
        );
      case ViewLayoutPB.Calendar:
        return CalendarPlugin(
          view: this,
          pluginType: pluginType,
          listenOnViewChanged: listenOnViewChanged,
        );
      case ViewLayoutPB.Grid:
        return GridPlugin(
          view: this,
          pluginType: pluginType,
          listenOnViewChanged: listenOnViewChanged,
        );
      case ViewLayoutPB.Document:
        return DocumentPlugin(
          view: this,
          pluginType: pluginType,
          listenOnViewChanged: listenOnViewChanged,
        );
    }
    throw UnimplementedError;
  }
}

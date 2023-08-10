import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/tar_bar/tab_bar_view.dart';
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

  Widget defaultIcon() {
    final iconName = switch (layout) {
      ViewLayoutPB.Board => 'editor/board',
      ViewLayoutPB.Calendar => 'editor/calendar',
      ViewLayoutPB.Grid => 'editor/grid',
      ViewLayoutPB.Document => 'editor/documents',
      _ => 'file_icon',
    };
    return FlowySvg(
      name: iconName,
    );
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
      case ViewLayoutPB.Calendar:
      case ViewLayoutPB.Grid:
        return DatabaseTabBarViewPlugin(
          view: this,
          pluginType: pluginType,
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

  DatabaseTabBarItemBuilder tarBarItem() {
    switch (layout) {
      case ViewLayoutPB.Board:
        return BoardPageTabBarBuilderImpl();
      case ViewLayoutPB.Calendar:
        return CalendarPageTabBarBuilderImpl();
      case ViewLayoutPB.Grid:
        return GridPageTabBarBuilderImpl();
      case ViewLayoutPB.Document:
        throw UnimplementedError;
    }
    throw UnimplementedError;
  }

  String get iconName {
    return layout.iconName;
  }
}

extension ViewLayoutExtension on ViewLayoutPB {
  String get iconName {
    switch (this) {
      case ViewLayoutPB.Grid:
        return 'editor/grid';
      case ViewLayoutPB.Board:
        return 'editor/board';
      case ViewLayoutPB.Calendar:
        return 'editor/date';
      case ViewLayoutPB.Document:
        return 'editor/documents';
      default:
        throw Exception('Unknown layout type');
    }
  }

  bool get isDatabaseView {
    switch (this) {
      case ViewLayoutPB.Grid:
      case ViewLayoutPB.Board:
      case ViewLayoutPB.Calendar:
        return true;
      case ViewLayoutPB.Document:
        return false;
      default:
        throw Exception('Unknown layout type');
    }
  }
}

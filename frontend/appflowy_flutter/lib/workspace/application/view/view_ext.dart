import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/tar_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/document/document.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
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
    const Widget widget = FlowySvg(FlowySvgs.page_s);
    return widget;
  }

  Widget defaultIcon() {
    return FlowySvg(
      switch (layout) {
        ViewLayoutPB.Board => FlowySvgs.board_s,
        ViewLayoutPB.Calendar => FlowySvgs.date_s,
        ViewLayoutPB.Grid => FlowySvgs.grid_s,
        ViewLayoutPB.Document => FlowySvgs.documents_s,
        _ => FlowySvgs.documents_s,
      },
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

  FlowySvgData get iconData => layout.icon;
}

extension ViewLayoutExtension on ViewLayoutPB {
  FlowySvgData get icon {
    switch (this) {
      case ViewLayoutPB.Grid:
        return FlowySvgs.grid_s;
      case ViewLayoutPB.Board:
        return FlowySvgs.board_s;
      case ViewLayoutPB.Calendar:
        return FlowySvgs.date_s;
      case ViewLayoutPB.Document:
        return FlowySvgs.documents_s;
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

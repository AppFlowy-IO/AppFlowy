import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/mobile_grid_page.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/document/document.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

enum FlowyPlugin { editor, kanban }

class PluginArgumentKeys {
  static String selection = "selection";
  static String rowId = "row_id";
}

extension ViewExtension on ViewPB {
  Widget defaultIcon() => FlowySvg(
        switch (layout) {
          ViewLayoutPB.Board => FlowySvgs.board_s,
          ViewLayoutPB.Calendar => FlowySvgs.date_s,
          ViewLayoutPB.Grid => FlowySvgs.grid_s,
          ViewLayoutPB.Document => FlowySvgs.document_s,
          _ => FlowySvgs.document_s,
        },
      );

  PluginType get pluginType => switch (layout) {
        ViewLayoutPB.Board => PluginType.board,
        ViewLayoutPB.Calendar => PluginType.calendar,
        ViewLayoutPB.Document => PluginType.editor,
        ViewLayoutPB.Grid => PluginType.grid,
        _ => throw UnimplementedError(),
      };

  Plugin plugin({
    Map<String, dynamic> arguments = const {},
  }) {
    switch (layout) {
      case ViewLayoutPB.Board:
      case ViewLayoutPB.Calendar:
      case ViewLayoutPB.Grid:
        final String? rowId = arguments[PluginArgumentKeys.rowId];

        return DatabaseTabBarViewPlugin(
          view: this,
          pluginType: pluginType,
          initialRowId: rowId,
        );
      case ViewLayoutPB.Document:
        final Selection? initialSelection =
            arguments[PluginArgumentKeys.selection];

        return DocumentPlugin(
          view: this,
          pluginType: pluginType,
          initialSelection: initialSelection,
        );
    }
    throw UnimplementedError;
  }

  DatabaseTabBarItemBuilder tabBarItem() => switch (layout) {
        ViewLayoutPB.Board => BoardPageTabBarBuilderImpl(),
        ViewLayoutPB.Calendar => CalendarPageTabBarBuilderImpl(),
        ViewLayoutPB.Grid => DesktopGridTabBarBuilderImpl(),
        _ => throw UnimplementedError,
      };

  DatabaseTabBarItemBuilder mobileTabBarItem() => switch (layout) {
        ViewLayoutPB.Board => BoardPageTabBarBuilderImpl(),
        ViewLayoutPB.Calendar => CalendarPageTabBarBuilderImpl(),
        ViewLayoutPB.Grid => MobileGridTabBarBuilderImpl(),
        _ => throw UnimplementedError,
      };

  FlowySvgData get iconData => layout.icon;
}

extension ViewLayoutExtension on ViewLayoutPB {
  FlowySvgData get icon => switch (this) {
        ViewLayoutPB.Grid => FlowySvgs.grid_s,
        ViewLayoutPB.Board => FlowySvgs.board_s,
        ViewLayoutPB.Calendar => FlowySvgs.date_s,
        ViewLayoutPB.Document => FlowySvgs.document_s,
        _ => throw Exception('Unknown layout type'),
      };

  bool get isDatabaseView => switch (this) {
        ViewLayoutPB.Grid ||
        ViewLayoutPB.Board ||
        ViewLayoutPB.Calendar =>
          true,
        ViewLayoutPB.Document => false,
        _ => throw Exception('Unknown layout type'),
      };
}

extension ViewFinder on List<ViewPB> {
  ViewPB? findView(String id) {
    for (final view in this) {
      if (view.id == id) {
        return view;
      }

      if (view.childViews.isNotEmpty) {
        final v = view.childViews.findView(id);
        if (v != null) {
          return v;
        }
      }
    }

    return null;
  }
}

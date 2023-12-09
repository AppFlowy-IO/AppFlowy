import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/mobile_grid_page.dart';
import 'package:appflowy/plugins/database_view/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/document/document.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart' hide id;
import 'package:flutter/material.dart';

enum FlowyPlugin {
  editor,
  kanban,
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

  Plugin plugin({bool listenOnViewChanged = false}) {
    switch (layout) {
      case ViewLayoutPB.Board:
      case ViewLayoutPB.Calendar:
      case ViewLayoutPB.Grid:
        return DatabaseTabBarViewPlugin(view: this, pluginType: pluginType);
      case ViewLayoutPB.Document:
        return DocumentPlugin(
          view: this,
          pluginType: pluginType,
          listenOnViewChanged: listenOnViewChanged,
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

  Future<List<ViewPB>> getAncestors({
    bool includeSelf = false,
    bool includeRoot = false,
  }) async {
    final ancestors = <ViewPB>[];
    if (includeSelf) {
      final self = await ViewBackendService.getView(id);
      ancestors.add(self.getLeftOrNull<ViewPB>() ?? this);
    }
    Either<ViewPB, FlowyError> parent =
        await ViewBackendService.getView(parentViewId);
    while (parent.isLeft()) {
      // parent is not null
      final view = parent.getLeftOrNull<ViewPB>();
      if (view == null || (!includeRoot && view.parentViewId.isEmpty)) {
        break;
      }
      ancestors.add(view);
      parent = await ViewBackendService.getView(view.parentViewId);
    }
    return ancestors.reversed.toList();
  }
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

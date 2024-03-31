import 'dart:convert';

import 'package:appflowy/mobile/presentation/database/board/mobile_board_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_grid_screen.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/workspace/application/recent/recent_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension MobileRouter on BuildContext {
  Future<void> pushView(ViewPB view, [Map<String, dynamic>? arguments]) async {
    await push(
      Uri(
        path: view.routeName,
        queryParameters: view.queryParameters(arguments),
      ).toString(),
    ).then((value) {
      RecentService().updateRecentViews([view.id], true);
    });
  }
}

extension on ViewPB {
  String get routeName {
    switch (layout) {
      case ViewLayoutPB.Document:
        return MobileDocumentScreen.routeName;
      case ViewLayoutPB.Grid:
        return MobileGridScreen.routeName;
      case ViewLayoutPB.Calendar:
        return MobileCalendarScreen.routeName;
      case ViewLayoutPB.Board:
        return MobileBoardScreen.routeName;
      default:
        throw UnimplementedError('routeName for $this is not implemented');
    }
  }

  Map<String, dynamic> queryParameters([Map<String, dynamic>? arguments]) {
    switch (layout) {
      case ViewLayoutPB.Document:
        return {
          MobileDocumentScreen.viewId: id,
          MobileDocumentScreen.viewTitle: name,
        };
      case ViewLayoutPB.Grid:
        return {
          MobileGridScreen.viewId: id,
          MobileGridScreen.viewTitle: name,
          MobileGridScreen.viewArgs: jsonEncode(arguments),
        };
      case ViewLayoutPB.Calendar:
        return {
          MobileCalendarScreen.viewId: id,
          MobileCalendarScreen.viewTitle: name,
        };
      case ViewLayoutPB.Board:
        return {
          MobileBoardScreen.viewId: id,
          MobileBoardScreen.viewTitle: name,
        };
      default:
        throw UnimplementedError(
          'queryParameters for $this is not implemented',
        );
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:appflowy/mobile/presentation/chat/mobile_chat_screen.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/mobile/presentation/database/board/mobile_board_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_grid_screen.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/recent/cached_recent_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:go_router/go_router.dart';

extension MobileRouter on BuildContext {
  Future<void> pushView(ViewPB view, [Map<String, dynamic>? arguments]) async {
    // set the current view before pushing the new view
    getIt<MenuSharedState>().latestOpenView = view;
    unawaited(getIt<CachedRecentService>().updateRecentViews([view.id], true));

    final uri = Uri(
      path: view.routeName,
      queryParameters: view.queryParameters(arguments),
    ).toString();
    await push(uri);
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
      case ViewLayoutPB.Chat:
        return MobileChatScreen.routeName;

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
      case ViewLayoutPB.Chat:
        return {
          MobileChatScreen.viewId: id,
          MobileChatScreen.viewTitle: name,
        };
      default:
        throw UnimplementedError(
          'queryParameters for $this is not implemented',
        );
    }
  }
}

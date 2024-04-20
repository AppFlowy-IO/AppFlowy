import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/recent/recent_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// This is a lazy-singleton to share recent views across the application.
///
/// This acts as a LaunchTask, so that it can be properly initialized/disposed
/// when needed by the application lifecycle.
///
/// Use-cases:
/// - Desktop: Command Palette recent view history
/// - Desktop: (Documents) Inline-page reference recent view history
/// - Mobile: Recent view history on home screen
///
class CachedRecentService extends LaunchTask {
  CachedRecentService();

  Completer<void> _completer = Completer();

  ValueNotifier<List<ViewPB>> notifier = ValueNotifier(const []);
  List<ViewPB> _recentViews = const [];
  final _listener = RecentViewsListener();

  Future<List<ViewPB>> recentViews() async {
    await _completer.future;
    return _recentViews;
  }

  /// Updates the recent views history
  Future<FlowyResult<void, FlowyError>> updateRecentViews(
    List<String> viewIds,
    bool addInRecent,
  ) async {
    return FolderEventUpdateRecentViews(
      UpdateRecentViewPayloadPB(viewIds: viewIds, addInRecent: addInRecent),
    ).send();
  }

  Future<FlowyResult<RepeatedViewPB, FlowyError>> _readRecentViews() =>
      FolderEventReadRecentViews().send();

  Future<void> _initialize() async {
    _listener.start(recentViewsUpdated: _recentViewsUpdated);
    final result = await _readRecentViews();
    _recentViews = result.toNullable()?.items ?? const [];
    notifier.value = _recentViews;
    _completer.complete();
  }

  @override
  Future<void> initialize(LaunchContext context) async => _initialize();

  @override
  Future<void> dispose() async {
    await _listener.stop();
  }

  void reset() {
    _resetCompleter();
    _initialize();
  }

  void _recentViewsUpdated(
    FlowyResult<RepeatedViewIdPB, FlowyError> result,
  ) {
    final viewIds = result.toNullable();
    if (viewIds != null) {
      _readRecentViews().then(
        (views) => _recentViews = views.toNullable()?.items ?? const [],
      );
    }
  }

  void _resetCompleter() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
    _completer = Completer<void>();
  }
}

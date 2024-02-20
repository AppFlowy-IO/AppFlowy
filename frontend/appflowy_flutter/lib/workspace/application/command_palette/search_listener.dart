import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/search_notification.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';

class SearchListener {
  PublishNotifier<RepeatedSearchResultPB>? _updateNotifier = PublishNotifier();
  PublishNotifier<RepeatedSearchResultPB>? _updateDidCloseNotifier =
      PublishNotifier();
  SearchNotificationListener? _listener;
  SearchListener();

  void start({
    required void Function(RepeatedSearchResultPB) onResultsChanged,
    required void Function(RepeatedSearchResultPB) onResultsClosed,
  }) {
    _updateNotifier?.addPublishListener(onResultsChanged);
    _updateDidCloseNotifier?.addPublishListener(onResultsClosed);
    _listener = SearchNotificationListener(
      objectId: "SEARCH_IDENTIFIER",
      handler: _handler,
    );
  }

  void _handler(SearchNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case SearchNotification.DidUpdateResults:
        result.fold(
          (payload) => _updateNotifier?.value =
              RepeatedSearchResultPB.fromBuffer(payload),
          (err) => Log.error(err),
        );
        break;
      case SearchNotification.DidCloseResults:
        result.fold(
          (payload) => _updateDidCloseNotifier?.value =
              RepeatedSearchResultPB.fromBuffer(payload),
          (err) => Log.error(err),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _updateNotifier?.dispose();
    _updateNotifier = null;
    _updateDidCloseNotifier?.dispose();
    _updateDidCloseNotifier = null;
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/workspace/domain/i_app.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'helper.dart';

class AppRepository {
  String appId;
  AppRepository({
    required this.appId,
  });

  Future<Either<App, FlowyError>> getAppDesc() {
    final request = QueryAppRequest.create()..appIds.add(appId);

    return FolderEventReadApp(request).send();
  }

  Future<Either<View, FlowyError>> createView(String name, String desc, ViewType viewType) {
    final request = CreateViewRequest.create()
      ..belongToId = appId
      ..name = name
      ..desc = desc
      ..viewType = viewType;

    return FolderEventCreateView(request).send();
  }

  Future<Either<List<View>, FlowyError>> getViews() {
    final request = QueryAppRequest.create()..appIds.add(appId);

    return FolderEventReadApp(request).send().then((result) {
      return result.fold(
        (app) => left(app.belongings.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> delete() {
    final request = QueryAppRequest.create()..appIds.add(appId);
    return FolderEventDeleteApp(request).send();
  }

  Future<Either<Unit, FlowyError>> updateApp({String? name}) {
    UpdateAppRequest request = UpdateAppRequest.create()..appId = appId;

    if (name != null) {
      request.name = name;
    }
    return FolderEventUpdateApp(request).send();
  }
}

class AppListenerRepository {
  StreamSubscription<SubscribeObject>? _subscription;
  AppViewsChangeCallback? _viewsChanged;
  AppUpdatedCallback? _update;
  late FolderNotificationParser _parser;
  String appId;

  AppListenerRepository({
    required this.appId,
  });

  void startListening({AppViewsChangeCallback? viewsChanged, AppUpdatedCallback? update}) {
    _viewsChanged = viewsChanged;
    _update = update;
    _parser = FolderNotificationParser(id: appId, callback: _bservableCallback);
    _subscription = RustStreamReceiver.listen((observable) => _parser.parse(observable));
  }

  void _bservableCallback(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.AppViewsChanged:
        if (_viewsChanged != null) {
          result.fold(
            (payload) {
              final repeatedView = RepeatedView.fromBuffer(payload);
              _viewsChanged!(left(repeatedView.items));
            },
            (error) => _viewsChanged!(right(error)),
          );
        }
        break;
      case FolderNotification.AppUpdated:
        if (_update != null) {
          result.fold(
            (payload) {
              final app = App.fromBuffer(payload);
              _update!(app);
            },
            (error) => Log.error(error),
          );
        }
        break;
      default:
        break;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }
}

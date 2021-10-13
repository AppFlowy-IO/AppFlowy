import 'dart:typed_data';
import 'package:flowy_sdk/protobuf/flowy-dart-notify/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:dartz/dartz.dart';

typedef UserObservableCallback = void Function(UserObservable, Either<Uint8List, UserError>);

class UserNotificationParser extends NotificationParser<UserObservable, UserError> {
  UserNotificationParser({required String id, required UserObservableCallback callback})
      : super(
          id: id,
          callback: callback,
          tyParser: (ty) => UserObservable.valueOf(ty),
          errorParser: (bytes) => UserError.fromBuffer(bytes),
        );
}

typedef NotificationCallback = void Function(Notification, Either<Uint8List, WorkspaceError>);

class WorkspaceNotificationParser extends NotificationParser<Notification, WorkspaceError> {
  WorkspaceNotificationParser({required String id, required NotificationCallback callback})
      : super(
          id: id,
          callback: callback,
          tyParser: (ty) => Notification.valueOf(ty),
          errorParser: (bytes) => WorkspaceError.fromBuffer(bytes),
        );
}

class NotificationParser<T, E> {
  String id;
  void Function(T, Either<Uint8List, E>) callback;

  T? Function(int) tyParser;
  E Function(Uint8List) errorParser;

  NotificationParser({required this.id, required this.callback, required this.errorParser, required this.tyParser});
  void parse(ObservableSubject subject) {
    if (subject.id != id) {
      return;
    }

    final ty = tyParser(subject.ty);
    if (ty == null) {
      return;
    }

    if (subject.hasPayload()) {
      final bytes = Uint8List.fromList(subject.payload);
      callback(ty, left(bytes));
    } else if (subject.hasError()) {
      final bytes = Uint8List.fromList(subject.error);
      final error = errorParser(bytes);
      callback(ty, right(error));
    } else {
      // do nothing
    }
  }
}

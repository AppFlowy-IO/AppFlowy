import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class NotificationParser<T, E extends Object> {
  NotificationParser({
    this.id,
    required this.callback,
    required this.errorParser,
    required this.tyParser,
  });

  String? id;
  void Function(T, FlowyResult<Uint8List, E>) callback;
  E Function(Uint8List) errorParser;
  T? Function(int, String) tyParser;

  void parse(SubscribeObject subject) {
    if (id != null) {
      if (subject.id != id) {
        return;
      }
    }

    final ty = tyParser(subject.ty, subject.source);
    if (ty == null) {
      return;
    }

    if (subject.hasError()) {
      final bytes = Uint8List.fromList(subject.error);
      final error = errorParser(bytes);
      callback(ty, FlowyResult.failure(error));
    } else {
      final bytes = Uint8List.fromList(subject.payload);
      callback(ty, FlowyResult.success(bytes));
    }
  }
}

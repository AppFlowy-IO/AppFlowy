import 'package:dartz/dartz.dart';
import 'package:flowy_protobuf/remote.dart';
import 'package:infra/uuid.dart';
import 'dart:typed_data';
import 'package:flowy_protobuf/all.dart';
import 'util.dart';

part 'auto_gen.dart';

class FlowyError {
  late StatusCode _statusCode;
  late String _error;
  late bool _has_error;

  StatusCode get statusCode {
    return _statusCode;
  }

  String get error {
    return _error;
  }

  bool get has_error {
    return _has_error;
  }

  String toString() {
    return "$_statusCode: $_error";
  }

  @override
  bool operator ==(other) {
    if (other is FlowyError) {
      return (this.statusCode == other.statusCode &&
          this._error == other._error);
    } else {
      return false;
    }
  }

  FlowyError({required StatusCode statusCode, required String error}) {
    _statusCode = statusCode;
    _error = error;
    _has_error = true;
  }

  factory FlowyError.from(ResponsePacket resp) {
    return FlowyError(statusCode: resp.statusCode, error: resp.err)
      .._has_error = resp.hasErr();
  }

  factory FlowyError.fromError(String error, StatusCode statusCode) {
    return FlowyError(statusCode: statusCode, error: error);
  }
}

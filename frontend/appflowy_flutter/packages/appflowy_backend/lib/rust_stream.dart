import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:appflowy_backend/log.dart';

import 'protobuf/flowy-notification/subject.pb.dart';

typedef ObserverCallback = void Function(SubscribeObject observable);

class RustStreamReceiver {
  static RustStreamReceiver shared = RustStreamReceiver._internal();
  late RawReceivePort _ffiPort;
  late StreamController<Uint8List> _streamController;
  late StreamController<SubscribeObject> _observableController;
  late StreamSubscription<Uint8List> _ffiSubscription;

  int get port => _ffiPort.sendPort.nativePort;
  StreamController<SubscribeObject> get observable => _observableController;

  RustStreamReceiver._internal() {
    _ffiPort = RawReceivePort();
    _streamController = StreamController();
    _observableController = StreamController.broadcast();

    _ffiPort.handler = _streamController.add;
    _ffiSubscription = _streamController.stream.listen(_streamCallback);
  }

  factory RustStreamReceiver() {
    return shared;
  }

  static StreamSubscription<SubscribeObject> listen(
      void Function(SubscribeObject subject) callback) {
    return RustStreamReceiver.shared.observable.stream.listen(callback);
  }

  void _streamCallback(Uint8List bytes) {
    try {
      final observable = SubscribeObject.fromBuffer(bytes);
      _observableController.add(observable);
    } catch (e, s) {
      Log.error(
          'RustStreamReceiver SubscribeObject deserialize error: ${e.runtimeType}');
      Log.error('Stack trace \n $s');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _ffiSubscription.cancel();
    await _streamController.close();
    await _observableController.close();
    _ffiPort.close();
  }
}

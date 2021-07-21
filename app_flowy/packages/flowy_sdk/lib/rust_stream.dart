import 'dart:isolate';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:flowy_infra/flowy_logger.dart';
import 'protobuf/flowy-observable/subject.pb.dart';

typedef ObserverCallback = void Function(ObservableSubject observable);

class RustStreamReceiver {
  static RustStreamReceiver shared = RustStreamReceiver._internal();
  late RawReceivePort _ffiPort;
  late StreamController<Uint8List> _streamController;
  late StreamController<ObservableSubject> _observableController;
  late StreamSubscription<Uint8List> _ffiSubscription;

  int get port => _ffiPort.sendPort.nativePort;
  StreamController<ObservableSubject> get observable => _observableController;

  RustStreamReceiver._internal() {
    _ffiPort = RawReceivePort();
    _streamController = StreamController();
    _observableController = StreamController.broadcast();

    _ffiPort.handler = _streamController.add;
    _ffiSubscription = _streamController.stream.listen(streamCallback);
  }

  factory RustStreamReceiver() {
    return shared;
  }

  static listen(void Function(ObservableSubject subject) callback) {
    RustStreamReceiver.shared.observable.stream.listen(callback);
  }

  void streamCallback(Uint8List bytes) {
    try {
      final observable = ObservableSubject.fromBuffer(bytes);
      _observableController.add(observable);
    } catch (e, s) {
      Log.error('RustStreamReceiver ObservableSubject deserialize error: ${e.runtimeType}');
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

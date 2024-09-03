import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-storage/protobuf.dart';
import 'package:flutter/foundation.dart';
import 'package:fixnum/fixnum.dart';

import '../startup.dart';

class FileStorageTask extends LaunchTask {
  const FileStorageTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    context.getIt.registerSingleton(
      FileStorageService(),
      dispose: (service) async {
        await service.dispose();
      },
    );
  }

  @override
  Future<void> dispose() async {}
}

class FileStorageService {
  FileStorageService() {
    _port.handler = _controller.add;
    _subscription = _controller.stream.listen(
      (event) {
        final fileProgress = FileProgress.fromJsonString(event);
        if (fileProgress != null) {
          Log.debug(
            "Upload progress: file: ${fileProgress.fileId} ${fileProgress.progress}",
          );
          final notifier = _notifierList[fileProgress.fileId];
          if (notifier != null) {
            notifier.value = fileProgress;
          }
        }
      },
    );

    final payload = RegisterStreamPB()..port = Int64(_port.sendPort.nativePort);
    FileStorageEventRegisterStream(payload).send();
  }

  final Map<String, AutoRemoveNotifier<FileProgress>> _notifierList = {};
  final RawReceivePort _port = RawReceivePort();
  final StreamController<String> _controller = StreamController.broadcast();
  late StreamSubscription<String> _subscription;

  AutoRemoveNotifier<FileProgress> onFileProgress({required String fileId}) {
    _notifierList.remove(fileId)?.dispose();

    final notifier = AutoRemoveNotifier<FileProgress>(
      FileProgress(fileId: fileId, progress: 0),
      notifierList: _notifierList,
      fileId: fileId,
    );
    _notifierList[fileId] = notifier;
    return notifier;
  }

  Future<void> dispose() async {
    // dispose all notifiers
    for (final notifier in _notifierList.values) {
      notifier.dispose();
    }

    await _controller.close();
    await _subscription.cancel();
    _port.close();
  }
}

class FileProgress {
  FileProgress({
    required this.fileId,
    required this.progress,
    this.error,
  });
  static FileProgress? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    if (json.containsKey('file_id') && json.containsKey('progress')) {
      return FileProgress(
        fileId: json['file_id'] as String,
        progress: (json['progress'] as num).toDouble(),
        error: json['error'] as String?,
      );
    } else {
      return null;
    }
  }

  // Method to parse a JSON string and return a FileProgress object or null
  static FileProgress? fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return FileProgress.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  final double progress;
  final String fileId;
  final String? error;
}

class AutoRemoveNotifier<T> extends ValueNotifier<T> {
  AutoRemoveNotifier(
    super.value, {
    required this.fileId,
    required Map<String, AutoRemoveNotifier<FileProgress>> notifierList,
  }) : _notifierList = notifierList;

  final String fileId;
  final Map<String, AutoRemoveNotifier<FileProgress>> _notifierList;

  @override
  void dispose() {
    _notifierList.remove(fileId);
    super.dispose();
  }
}

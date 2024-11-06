import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-storage/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:fixnum/fixnum.dart';

import '../startup.dart';

class FileStorageTask extends LaunchTask {
  const FileStorageTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    context.getIt.registerSingleton(FileStorageService());
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
            "Upload progress: file: ${fileProgress.fileUrl} ${fileProgress.progress}",
          );
          final notifier = _notifierList[fileProgress.fileUrl];
          if (notifier != null) {
            notifier.value = fileProgress;
          }
        }
      },
    );

    if (!integrationMode().isTest) {
      final payload = RegisterStreamPB()
        ..port = Int64(_port.sendPort.nativePort);
      FileStorageEventRegisterStream(payload).send();
    }
  }

  final Map<String, AutoRemoveNotifier<FileProgress>> _notifierList = {};
  final RawReceivePort _port = RawReceivePort();
  final StreamController<String> _controller = StreamController.broadcast();
  late StreamSubscription<String> _subscription;

  AutoRemoveNotifier<FileProgress> onFileProgress({required String fileUrl}) {
    _notifierList.remove(fileUrl)?.dispose();

    final notifier = AutoRemoveNotifier<FileProgress>(
      FileProgress(fileUrl: fileUrl, progress: 0),
      notifierList: _notifierList,
      fileId: fileUrl,
    );
    _notifierList[fileUrl] = notifier;

    // trigger the initial file state
    getFileState(fileUrl);

    return notifier;
  }

  Future<FlowyResult<FileStatePB, FlowyError>> getFileState(String url) {
    final payload = QueryFilePB()..url = url;
    return FileStorageEventQueryFile(payload).send();
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
    required this.fileUrl,
    required this.progress,
    this.error,
  });

  static FileProgress? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    try {
      if (json.containsKey('file_url') && json.containsKey('progress')) {
        return FileProgress(
          fileUrl: json['file_url'] as String,
          progress: (json['progress'] as num).toDouble(),
          error: json['error'] as String?,
        );
      }
    } catch (e) {
      Log.error('unable to parse file progress: $e');
    }
    return null;
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
  final String fileUrl;
  final String? error;

  @override
  String toString() =>
      'FileProgress(progress: $progress, fileUrl: $fileUrl, error: $error)';
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

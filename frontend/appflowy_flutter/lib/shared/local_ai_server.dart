import 'dart:async';
import 'dart:io';

import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String kLocalAIServerPrefix = 'appflowy_ai_';

class LocalAIServer {
  LocalAIServer._internal();

  factory LocalAIServer() => _instance;

  static final LocalAIServer _instance = LocalAIServer._internal();

  Future<(bool, int?)> launch({
    required String localLLMPath,
    String host = '127.0.0.1',
    int? port,
  }) async {
    final executablePath = await getExecutablePath();

    if (port == null && host == '127.0.0.1') {
      // use a free port
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      port = socket.port;
      await socket.close();
    }

    await terminate();

    try {
      final server = await Process.start(
        executablePath,
        [host, port.toString()],
      );
      // No need to wait for the exitCode because it won't return an exit code until the server is terminated
      int? exitCode;
      unawaited(
        server.exitCode.then(
          (value) => exitCode = value,
        ),
      );

      // the server will return error immediately if it launch failed.
      await Future.delayed(const Duration(milliseconds: 500));

      if (exitCode != null && exitCode != 0) {
        debugPrint('Failed to launch server. Exit code: $exitCode');
        return (false, null);
      }
      debugPrint('Server launched at $host:$port');
      return (true, port);
    } catch (e) {
      debugPrint('unable to launch server: $e');
    }

    return (false, null);
  }

  Future<void> terminate() async {
    final executablePath = await getExecutablePath();

    if (Platform.isMacOS || Platform.isLinux) {
      await Process.run('pkill', [executablePath]);
    } else if (Platform.isWindows) {
      await Process.run('taskkill', ['/F', '/IM', executablePath]);
    }
  }

  Future<FlowyResult<void, FlowyError>> pingServer(
    String host,
    int port,
  ) async {
    try {
      final response = await http.get(Uri.parse('http://$host:$port/'));
      if (response.statusCode != 200) {
        return FlowyFailure(
          FlowyError(
            code: ErrorCode.Internal,
            msg: 'Failed to ping server ${response.statusCode}',
          ),
        );
      }
      return FlowySuccess(null);
    } catch (e) {
      return FlowyFailure(
        FlowyError(
          code: ErrorCode.Internal,
          msg: 'Failed to ping server: $e',
        ),
      );
    }
  }

  Future<String> getExecutablePath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // final dir = await getApplicationSupportDirectory();
      final executablePath = p.join(dir.path, getExecutableName());
      final executable = File(executablePath);
      if (!executable.existsSync()) {
        final bytes = await rootBundle.load('assets/ai/${getExecutableName()}');
        await executable.writeAsBytes(bytes.buffer.asUint8List());
        debugPrint('Executable written to $executablePath');
      }

      // make it executable because the permission is not preserved when writing the file
      if (Platform.isMacOS || Platform.isLinux) {
        await Process.run('chmod', [
          'u+x',
          executablePath,
        ]);
      }

      return executablePath;
    } catch (e) {
      throw Exception('Failed to get executable path: $e');
    }
  }

  String getExecutableName() {
    var name = kLocalAIServerPrefix;
    if (Platform.isMacOS) {
      name += 'osx';
    } else if (Platform.isWindows) {
      name += 'win';
    } else if (Platform.isLinux) {
      name += 'lnx';
    }
    return name;
  }
}

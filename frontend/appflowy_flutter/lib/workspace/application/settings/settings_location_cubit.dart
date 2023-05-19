import 'dart:io';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../startup/tasks/prelude.dart';

part 'settings_location_cubit.freezed.dart';

@freezed
class SettingsLocationState with _$SettingsLocationState {
  const factory SettingsLocationState.initial() = _Initial;
  const factory SettingsLocationState.didReceivedPath(String path) =
      _DidReceivedPath;
}

class SettingsLocationCubit extends Cubit<SettingsLocationState> {
  SettingsLocationCubit() : super(const SettingsLocationState.initial()) {
    _init();
  }

  Future<void> setPath(String path) async {
    await getIt<LocalFileStorage>().setPath(path);
    emit(SettingsLocationState.didReceivedPath(path));
  }

  Future<void> _init() async {
    final path = await getIt<LocalFileStorage>().getPath();
    emit(SettingsLocationState.didReceivedPath(path));
  }
}

class LocalFileStorage {
  LocalFileStorage();
  String? _cachePath;

  Future<void> setPath(String path) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      Log.info('LocalFileStorage is not supported on this platform.');
      return;
    }

    if (Platform.isMacOS) {
      // remove the prefix `/Volumes/*`
      path = path.replaceFirst(RegExp(r'^/Volumes/[^/]+'), '');
    } else if (Platform.isWindows) {
      path = path.replaceAll('/', '\\');
    }

    await getIt<KeyValueStorage>().set(KVKeys.pathLocation, path);
    // clear the cache path, and not set the cache path to the new path because the set path may be invalid
    _cachePath = null;
  }

  Future<String> getPath() async {
    if (_cachePath != null) {
      return _cachePath!;
    }

    final response = await getIt<KeyValueStorage>().get(KVKeys.pathLocation);
    final String path = await response.fold(
      (error) async {
        // return the default path if the path is not set
        final directory = await appFlowyDocumentDirectory();
        return directory.path;
      },
      (path) => path,
    );
    _cachePath = path;

    // if the path is not exists means the path is invalid, so we should clear the kv store
    if (!Directory(path).existsSync()) {
      await getIt<KeyValueStorage>().clear();
    }

    return path;
  }
}

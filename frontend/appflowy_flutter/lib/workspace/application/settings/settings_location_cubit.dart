import 'dart:io';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

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

  Future<void> resetDataStoragePathToApplicationDefault() async {
    final directory = await appFlowyApplicationDataDirectory();
    await getIt<ApplicationDataStorage>()._setPath(directory.path);
    emit(SettingsLocationState.didReceivedPath(directory.path));
  }

  Future<void> setCustomPath(String path) async {
    await getIt<ApplicationDataStorage>().setCustomPath(path);
    emit(SettingsLocationState.didReceivedPath(path));
  }

  Future<void> _init() async {
    final path = await getIt<ApplicationDataStorage>().getPath();
    emit(SettingsLocationState.didReceivedPath(path));
  }
}

class ApplicationDataStorage {
  ApplicationDataStorage();
  String? _cachePath;

  /// Set the custom path to store the data.
  /// If the path is not exists, the path will be created.
  /// If the path is invalid, the path will be set to the default path.
  Future<void> setCustomPath(String path) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      Log.info('LocalFileStorage is not supported on this platform.');
      return;
    }

    // Every custom path will have a folder named `AppFlowyData`
    const dataFolder = "AppFlowyData";

    if (Platform.isMacOS) {
      // remove the prefix `/Volumes/*`
      path = path.replaceFirst(RegExp(r'^/Volumes/[^/]+'), '');
    } else if (Platform.isWindows) {
      path = path.replaceAll('/', '\\');
    }

    // If the path is not ends with `AppFlowyData`, we will append the
    // `AppFlowyData` to the path. If the path is ends with `AppFlowyData`,
    // which means the path is the custom path.
    if (p.basename(path) != dataFolder) {
      path = p.join(path, dataFolder);
    }

    // create the directory if not exists.
    final directory = Directory(path);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    _setPath(path);
  }

  Future<void> _setPath(String path) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      Log.info('LocalFileStorage is not supported on this platform.');
      return;
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
        final directory = await appFlowyApplicationDataDirectory();
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

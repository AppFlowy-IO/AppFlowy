import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../startup/tasks/prelude.dart';

@visibleForTesting
const String kSettingsLocationDefaultLocation =
    'kSettingsLocationDefaultLocation';

class SettingsLocation {
  SettingsLocation({
    String? path,
  }) : _path = path;

  String? _path;

  set path(String? path) {
    _path = path;
  }

  String? get path {
    if (Platform.isMacOS) {
      // remove the prefix `/Volumes/*`
      return _path?.replaceFirst(RegExp(r'^/Volumes/[^/]+'), '');
    }
    return _path;
  }

  SettingsLocation copyWith({String? path}) {
    return SettingsLocation(
      path: path ?? this.path,
    );
  }
}

class SettingsLocationCubit extends Cubit<SettingsLocation> {
  SettingsLocationCubit() : super(SettingsLocation(path: null));

  /// Returns a path that used to store user data
  Future<String> fetchLocation() async {
    final prefs = await SharedPreferences.getInstance();

    /// Use the [appFlowyDocumentDirectory] instead if there is no user
    /// preference location
    final path = prefs.getString(kSettingsLocationDefaultLocation) ??
        (await appFlowyDocumentDirectory()).path;

    emit(state.copyWith(path: path));
    return Future.value(path);
  }

  /// Saves the user preference local data store location
  Future<void> setLocation(String? path) async {
    path = path ?? (await appFlowyDocumentDirectory()).path;

    assert(path.isNotEmpty);
    if (path.isEmpty) {
      path = (await appFlowyDocumentDirectory()).path;
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(kSettingsLocationDefaultLocation, path);
    await Directory(path).create(recursive: true);
    emit(state.copyWith(path: path));
  }
}

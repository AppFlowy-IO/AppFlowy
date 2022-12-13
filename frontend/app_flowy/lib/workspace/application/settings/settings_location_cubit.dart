import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../startup/tasks/prelude.dart';

const String _kSettingsLocationDefaultLocation =
    'kSettingsLocationDefaultLocation';

class SettingsLocation {
  SettingsLocation({
    this.path,
  });

  String? path;

  SettingsLocation copyWith({String? path}) {
    return SettingsLocation(
      path: path ?? this.path,
    );
  }
}

class SettingsLocationCubit extends Cubit<SettingsLocation> {
  SettingsLocationCubit() : super(SettingsLocation(path: null));

  Future<String> fetchLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kSettingsLocationDefaultLocation) ??
        (await appFlowyDocumentDirectory()).path;
    emit(state.copyWith(path: path));
    return Future.value(path);
  }

  Future<void> setLocation(String? path) async {
    path = path ?? (await appFlowyDocumentDirectory()).path;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_kSettingsLocationDefaultLocation, path);
    await Directory(path).create(recursive: true);
    emit(state.copyWith(path: path));
  }
}

import 'package:app_flowy/startup/tasks/prelude.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String? getLocation() {
    return state.path;
  }

  Future<String> fetchLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kSettingsLocationDefaultLocation) ??
        (await appFlowyDocumentDirectory()).path;
    state.path = path;
    return Future.value(path);
  }

  Future<bool> setLocation(String? path) async {
    path = path ?? (await appFlowyDocumentDirectory()).path;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kSettingsLocationDefaultLocation, path);
  }
}

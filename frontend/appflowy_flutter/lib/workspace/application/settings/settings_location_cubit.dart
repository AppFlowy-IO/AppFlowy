import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
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

  Future<void> resetDataStoragePathToApplicationDefault() async {
    final directory = await appFlowyApplicationDataDirectory();
    await getIt<ApplicationDataStorage>().setPath(directory.path);
    emit(SettingsLocationState.didReceivedPath(directory.path));
  }

  Future<void> setCustomPath(String path) async {
    await getIt<ApplicationDataStorage>().setCustomPath(path);
    emit(SettingsLocationState.didReceivedPath(path));
  }

  Future<void> _init() async {
    // The backend might change the real path that storge the data. So it needs
    // to get the path from the backend instead of the KeyValueStorage
    await UserEventGetUserSetting().send().then((result) {
      result.fold(
        (l) => emit(SettingsLocationState.didReceivedPath(l.userFolder)),
        (r) => Log.error(r),
      );
    });
  }
}

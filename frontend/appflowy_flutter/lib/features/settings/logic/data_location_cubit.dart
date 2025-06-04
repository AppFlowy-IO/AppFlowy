import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../startup/tasks/prelude.dart';

class DataLocationCubit extends Cubit<DataLocationState> {
  DataLocationCubit() : super(const DataLocationLoading()) {
    _init();
  }

  void _init() async {
    // The backend might change the real path that storge the data. So it needs
    // to get the path from the backend instead of the KeyValueStorage
    final defaultDirectory = (await appFlowyApplicationDataDirectory()).path;

    final result = await UserSettingsBackendService().getUserSetting();
    final userDirectory = result.toNullable()?.userFolder;

    if (userDirectory != null) {
      emit(
        DataLocationReady(
          path: userDirectory,
          isCustom: userDirectory.contains(defaultDirectory),
        ),
      );
    }
  }

  Future<void> resetDataStoragePathToApplicationDefault() async {
    final directory = await appFlowyApplicationDataDirectory();
    await getIt<ApplicationDataStorage>().setPath(directory.path);
    emit(
      DataLocationReady(
        path: directory.path,
        isCustom: false,
      ),
    );
  }

  // Future<void> setCustomPath(String path) async {
  //   await getIt<ApplicationDataStorage>().setCustomPath(path);
  //   emit(SettingsLocationState.didReceivedPath(path));
  // }
}

sealed class DataLocationState {
  const DataLocationState();
}

class DataLocationLoading extends DataLocationState {
  const DataLocationLoading();
}

class DataLocationReady extends DataLocationState {
  const DataLocationReady({
    required this.path,
    required this.isCustom,
  });

  final String path;
  final bool isCustom;
}

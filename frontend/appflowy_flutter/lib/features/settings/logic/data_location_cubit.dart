import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../startup/tasks/prelude.dart';
import '../data/models/user_data_location.dart';
import '../data/repositories/settings_repository.dart';

class DataLocationCubit extends Cubit<DataLocationState> {
  DataLocationCubit({
    required SettingsRepository repository,
  })  : _repository = repository,
        super(DataLocationState.initial()) {
    _init();
  }

  final SettingsRepository _repository;

  void _init() async {
    final result = await _repository.getUserDataLocation();
    final userDataLocation = result.fold(
      (userDataLocation) => userDataLocation,
      (error) => null,
    );

    if (userDataLocation != null) {
      emit(
        DataLocationState(
          userDataLocation: userDataLocation,
        ),
      );
    }
  }

  Future<void> resetDataStoragePathToApplicationDefault() async {
    final directory = await appFlowyApplicationDataDirectory();
    await getIt<ApplicationDataStorage>().setPath(directory.path);
    emit(
      DataLocationState(
        userDataLocation: UserDataLocation(
          path: directory.path,
          isCustom: false,
        ),
      ),
    );
  }

  // Future<void> setCustomPath(String path) async {
  //   await getIt<ApplicationDataStorage>().setCustomPath(path);
  //   emit(SettingsLocationState.didReceivedPath(path));
  // }
}

class DataLocationState {
  const DataLocationState({
    required this.userDataLocation,
  });

  factory DataLocationState.initial() =>
      const DataLocationState(userDataLocation: null);

  final UserDataLocation? userDataLocation;
}

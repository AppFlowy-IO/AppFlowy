import 'package:appflowy/startup/tasks/rust_sdk.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

import '../models/user_data_location.dart';
import 'settings_repository.dart';

class RustSettingsRepositoryImpl implements SettingsRepository {
  const RustSettingsRepositoryImpl();

  final _userBackendService = const UserSettingsBackendService();

  @override
  Future<FlowyResult<UserDataLocation, FlowyError>>
      getUserDataLocation() async {
    final defaultDirectory = (await appFlowyApplicationDataDirectory()).path;
    final result = await _userBackendService.getUserSetting();

    return result.map(
      (settings) {
        final userDirectory = settings.userFolder;
        return UserDataLocation(
          path: userDirectory,
          isCustom: userDirectory.contains(defaultDirectory),
        );
      },
    );
  }
}

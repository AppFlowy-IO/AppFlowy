import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

import '../models/user_data_location.dart';

abstract class SettingsRepository {
  Future<FlowyResult<UserDataLocation, FlowyError>> getUserDataLocation();

  Future<FlowyResult<UserDataLocation, FlowyError>> resetUserDataLocation();
}

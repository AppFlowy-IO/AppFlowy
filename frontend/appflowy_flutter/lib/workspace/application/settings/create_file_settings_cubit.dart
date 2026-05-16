import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateFileSettingsCubit extends Cubit<bool> {
  CreateFileSettingsCubit(super.initialState) {
    getInitialSettings();
  }

  Future<void> toggle({bool? value}) async {
    await getIt<KeyValueStorage>().set(
      KVKeys.showRenameDialogWhenCreatingNewFile,
      (value ?? !state).toString(),
    );
    emit(value ?? !state);
  }

  Future<void> getInitialSettings() async {
    final settingsOrFailure = await getIt<KeyValueStorage>().getWithFormat(
      KVKeys.showRenameDialogWhenCreatingNewFile,
      (value) => bool.parse(value),
    );
    emit(settingsOrFailure ?? false);
  }
}

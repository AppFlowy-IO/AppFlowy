import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/import_data.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'setting_file_importer_bloc.freezed.dart';

class SettingFileImportBloc
    extends Bloc<SettingFileImportEvent, SettingFileImportState> {
  SettingFileImportBloc() : super(SettingFileImportState.initial()) {
    on<SettingFileImportEvent>(
      (event, emit) async {
        await event.when(
          importAppFlowyDataFolder: (String path) async {
            final formattedDate =
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
            final spaceId =
                await getIt<KeyValueStorage>().get(KVKeys.lastOpenedSpaceId);

            final payload = ImportAppFlowyDataPB.create()
              ..path = path
              ..importContainerName = "import_$formattedDate";

            if (spaceId != null) {
              payload.parentViewId = spaceId;
            }

            emit(
              state.copyWith(loadingState: const LoadingState.loading()),
            );
            final result =
                await UserEventImportAppFlowyDataFolder(payload).send();
            if (!isClosed) {
              add(SettingFileImportEvent.finishImport(result));
            }
          },
          finishImport: (result) {
            result.fold(
              (l) {
                emit(
                  state.copyWith(
                    successOrFail: FlowyResult.success(null),
                    loadingState:
                        LoadingState.finish(FlowyResult.success(null)),
                  ),
                );
              },
              (err) {
                Log.error(err);
                emit(
                  state.copyWith(
                    successOrFail: FlowyResult.failure(err),
                    loadingState: LoadingState.finish(FlowyResult.failure(err)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

@freezed
class SettingFileImportEvent with _$SettingFileImportEvent {
  const factory SettingFileImportEvent.importAppFlowyDataFolder(String path) =
      _ImportAppFlowyDataFolder;
  const factory SettingFileImportEvent.finishImport(
    FlowyResult<void, FlowyError> result,
  ) = _ImportResult;
}

@freezed
class SettingFileImportState with _$SettingFileImportState {
  const factory SettingFileImportState({
    required LoadingState loadingState,
    required FlowyResult<void, FlowyError>? successOrFail,
  }) = _SettingFileImportState;

  factory SettingFileImportState.initial() => const SettingFileImportState(
        loadingState: LoadingState.idle(),
        successOrFail: null,
      );
}

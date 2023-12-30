import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/import.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'setting_file_importer_bloc.freezed.dart';

class SettingFileImporterBloc
    extends Bloc<SettingFileImportEvent, SettingFileImportState> {
  SettingFileImporterBloc() : super(SettingFileImportState.initial()) {
    on<SettingFileImportEvent>((event, emit) async {
      await event.when(
        importAppFlowyDataFolder: (String path) async {
          final payload = ImportAppFlowyDataPB.create()..path = path;
          final result =
              await FolderEventImportAppFlowyDataFolder(payload).send();
          result.fold(
            (l) {
              emit(
                state.copyWith(
                  successOrFail: some(left(unit)),
                ),
              );
            },
            (err) {
              Log.error(err);
              emit(
                state.copyWith(
                  successOrFail: some(right(err)),
                ),
              );
            },
          );
        },
      );
    });
  }
}

@freezed
class SettingFileImportEvent with _$SettingFileImportEvent {
  const factory SettingFileImportEvent.importAppFlowyDataFolder(String path) =
      _ImportAppFlowyDataFolder;
}

@freezed
class SettingFileImportState with _$SettingFileImportState {
  const factory SettingFileImportState({
    required Option<Either<Unit, FlowyError>> successOrFail,
  }) = _SettingFileImportState;

  factory SettingFileImportState.initial() => SettingFileImportState(
        successOrFail: none(),
      );
}

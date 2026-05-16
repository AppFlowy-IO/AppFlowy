import 'dart:io';

import 'package:appflowy/workspace/application/settings/share/export_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_bloc.freezed.dart';

class DatabaseShareBloc extends Bloc<DatabaseShareEvent, DatabaseShareState> {
  DatabaseShareBloc({
    required this.view,
  }) : super(const DatabaseShareState.initial()) {
    on<ShareCSV>(_onShareCSV);
  }

  final ViewPB view;

  Future<void> _onShareCSV(
    ShareCSV event,
    Emitter<DatabaseShareState> emit,
  ) async {
    emit(const DatabaseShareState.loading());

    final result = await BackendExportService.exportDatabaseAsCSV(view.id);
    result.fold(
      (l) => _saveCSVToPath(l.data, event.path),
      (r) => Log.error(r),
    );

    emit(
      DatabaseShareState.finish(
        result.fold(
          (l) {
            _saveCSVToPath(l.data, event.path);
            return FlowyResult.success(null);
          },
          (r) => FlowyResult.failure(r),
        ),
      ),
    );
  }

  ExportDataPB _saveCSVToPath(String markdown, String path) {
    File(path).writeAsStringSync(markdown);
    return ExportDataPB()
      ..data = markdown
      ..exportType = ExportType.Markdown;
  }
}

@freezed
class DatabaseShareEvent with _$DatabaseShareEvent {
  const factory DatabaseShareEvent.shareCSV(String path) = ShareCSV;
}

@freezed
class DatabaseShareState with _$DatabaseShareState {
  const factory DatabaseShareState.initial() = _Initial;
  const factory DatabaseShareState.loading() = _Loading;
  const factory DatabaseShareState.finish(
    FlowyResult<void, FlowyError> successOrFail,
  ) = _Finish;
}

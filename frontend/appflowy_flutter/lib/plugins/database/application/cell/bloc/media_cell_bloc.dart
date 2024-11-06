import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/file_storage_task.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_cell_bloc.freezed.dart';

class MediaCellBloc extends Bloc<MediaCellEvent, MediaCellState> {
  MediaCellBloc({
    required this.cellController,
  }) : super(MediaCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  late final RowBackendService _rowService =
      RowBackendService(viewId: cellController.viewId);
  final MediaCellController cellController;
  final FileStorageService _fileStorageService = getIt<FileStorageService>();
  final Map<String, AutoRemoveNotifier<FileProgress>> _progressNotifiers = {};

  void Function()? _onCellChangedFn;

  String get databaseId => cellController.viewId;
  String get rowId => cellController.rowId;
  bool get wrapContent => cellController.fieldInfo.wrapCellContent ?? false;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(
        onCellChanged: _onCellChangedFn!,
        onFieldChanged: _onFieldChangedListener,
      );
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<MediaCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _checkFileStatus();

            // Fetch user profile
            final userProfileResult =
                await UserBackendService.getCurrentUserProfile();
            userProfileResult.fold(
              (userProfile) => emit(state.copyWith(userProfile: userProfile)),
              (l) => Log.error(l),
            );
          },
          didUpdateCell: (files) {
            emit(state.copyWith(files: files));
          },
          didUpdateField: (fieldName) {
            final typeOption =
                cellController.getTypeOption(MediaTypeOptionDataParser());

            emit(
              state.copyWith(
                fieldName: fieldName,
                hideFileNames: typeOption.hideFileNames,
              ),
            );
          },
          addFile: (url, name, uploadType, fileType) async {
            final newFile = MediaFilePB(
              id: uuid(),
              url: url,
              name: name,
              uploadType: uploadType,
              fileType: fileType,
            );

            final payload = MediaCellChangesetPB(
              viewId: cellController.viewId,
              cellId: CellIdPB(
                viewId: cellController.viewId,
                fieldId: cellController.fieldId,
                rowId: cellController.rowId,
              ),
              insertedFiles: [newFile],
              removedIds: [],
            );

            final result = await DatabaseEventUpdateMediaCell(payload).send();
            result.fold(
              (_) => _registerProgressNotifier(newFile),
              (err) => Log.error(err),
            );
          },
          removeFile: (id) async {
            _removeNotifier(id);

            final payload = MediaCellChangesetPB(
              viewId: cellController.viewId,
              cellId: CellIdPB(
                viewId: cellController.viewId,
                fieldId: cellController.fieldId,
                rowId: cellController.rowId,
              ),
              insertedFiles: [],
              removedIds: [id],
            );

            final result = await DatabaseEventUpdateMediaCell(payload).send();
            result.fold((l) => null, (err) => Log.error(err));
          },
          reorderFiles: (from, to) async {
            final files = List<MediaFilePB>.from(state.files);
            files.insert(to, files.removeAt(from));

            // We emit the new state first to update the UI
            emit(state.copyWith(files: files));

            final payload = MediaCellChangesetPB(
              viewId: cellController.viewId,
              cellId: CellIdPB(
                viewId: cellController.viewId,
                fieldId: cellController.fieldId,
                rowId: cellController.rowId,
              ),
              insertedFiles: files,
              // In the backend we remove all files by id before we do inserts.
              // So this will effectively reorder the files.
              removedIds: files.map((file) => file.id).toList(),
            );

            final result = await DatabaseEventUpdateMediaCell(payload).send();
            result.fold((l) => null, (err) => Log.error(err));
          },
          renameFile: (fileId, name) async {
            final payload = RenameMediaChangesetPB(
              viewId: cellController.viewId,
              cellId: CellIdPB(
                viewId: cellController.viewId,
                fieldId: cellController.fieldId,
                rowId: cellController.rowId,
              ),
              fileId: fileId,
              name: name,
            );

            final result = await DatabaseEventRenameMediaFile(payload).send();
            result.fold((l) => null, (err) => Log.error(err));
          },
          toggleShowAllFiles: () {
            emit(state.copyWith(showAllFiles: !state.showAllFiles));
          },
          setCover: (cover) => _rowService.updateMeta(
            rowId: cellController.rowId,
            cover: cover,
          ),
          onProgressUpdate: (id) {
            final FileProgress? progress = _progressNotifiers[id]?.value;
            if (progress != null) {
              MediaUploadProgress? mediaUploadProgress =
                  state.uploadProgress.firstWhereOrNull((u) => u.fileId == id);

              if (progress.error != null) {
                // Remove file from cell
                add(MediaCellEvent.removeFile(fileId: id));
                _removeNotifier(id);

                // Remove progress
                final uploadProgress = [...state.uploadProgress];
                uploadProgress.removeWhere((u) => u.fileId == id);
                emit(state.copyWith(uploadProgress: uploadProgress));
                return;
              }

              mediaUploadProgress ??= MediaUploadProgress(
                fileId: id,
                uploadState: progress.progress >= 1
                    ? MediaUploadState.completed
                    : MediaUploadState.uploading,
                fileProgress: progress,
              );

              final uploadProgress = [...state.uploadProgress];
              uploadProgress
                ..removeWhere((u) => u.fileId == id)
                ..add(mediaUploadProgress);

              emit(state.copyWith(uploadProgress: uploadProgress));
            }
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellData) {
        if (!isClosed) {
          add(MediaCellEvent.didUpdateCell(cellData?.files ?? const []));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  /// We check the file state of all the files that are in Cloud (hosted by us) in the cell.
  ///
  /// If any file has failed, we should notify the user about it,
  /// and also remove it from the cell.
  ///
  /// This method registers the progress notifiers for each file.
  ///
  void _checkFileStatus() {
    for (final file in state.files) {
      _registerProgressNotifier(file);
    }
  }

  void _registerProgressNotifier(MediaFilePB file) {
    if (file.uploadType != FileUploadTypePB.CloudFile) {
      return;
    }

    final notifier = _fileStorageService.onFileProgress(fileUrl: file.url);
    _progressNotifiers[file.id] = notifier;
    notifier.addListener(() => _onProgressChanged(file.id));

    add(MediaCellEvent.onProgressUpdate(file.id));
  }

  void _onProgressChanged(String id) =>
      add(MediaCellEvent.onProgressUpdate(id));

  /// Removes and disposes of a progress notifier if found
  ///
  void _removeNotifier(String id) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final notifier = _progressNotifiers.remove(id);
      notifier?.removeListener(() => _onProgressChanged(id));
      notifier?.dispose();
    });
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(MediaCellEvent.didUpdateField(fieldInfo.name));
    }
  }

  void renameFile(String fileId, String name) =>
      add(MediaCellEvent.renameFile(fileId: fileId, name: name));

  void deleteFile(String fileId) =>
      add(MediaCellEvent.removeFile(fileId: fileId));
}

@freezed
class MediaCellEvent with _$MediaCellEvent {
  const factory MediaCellEvent.initial() = _Initial;

  const factory MediaCellEvent.didUpdateCell(List<MediaFilePB> files) =
      _DidUpdateCell;

  const factory MediaCellEvent.didUpdateField(String fieldName) =
      _DidUpdateField;

  const factory MediaCellEvent.addFile({
    required String url,
    required String name,
    required FileUploadTypePB uploadType,
    required MediaFileTypePB fileType,
  }) = _AddFile;

  const factory MediaCellEvent.removeFile({
    required String fileId,
  }) = _RemoveFile;

  const factory MediaCellEvent.reorderFiles({
    required int from,
    required int to,
  }) = _ReorderFiles;

  const factory MediaCellEvent.renameFile({
    required String fileId,
    required String name,
  }) = _RenameFile;

  const factory MediaCellEvent.toggleShowAllFiles() = _ToggleShowAllFiles;

  const factory MediaCellEvent.setCover(RowCoverPB cover) = _SetCover;

  const factory MediaCellEvent.onProgressUpdate(String fileId) =
      _OnProgressUpdate;
}

@freezed
class MediaCellState with _$MediaCellState {
  const factory MediaCellState({
    UserProfilePB? userProfile,
    required String fieldName,
    @Default([]) List<MediaFilePB> files,
    @Default(false) showAllFiles,
    @Default(true) hideFileNames,
    @Default([]) List<MediaUploadProgress> uploadProgress,
  }) = _MediaCellState;

  factory MediaCellState.initial(MediaCellController cellController) {
    final cellData = cellController.getCellData();
    final typeOption =
        cellController.getTypeOption(MediaTypeOptionDataParser());

    return MediaCellState(
      fieldName: cellController.fieldInfo.field.name,
      files: cellData?.files ?? const [],
      hideFileNames: typeOption.hideFileNames,
    );
  }
}

enum MediaUploadState { uploading, completed }

class MediaUploadProgress {
  const MediaUploadProgress({
    required this.fileId,
    required this.uploadState,
    required this.fileProgress,
  });

  final String fileId;
  final MediaUploadState uploadState;
  final FileProgress fileProgress;
}

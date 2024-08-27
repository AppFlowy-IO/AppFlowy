import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_cell_bloc.freezed.dart';

class MediaCellBloc extends Bloc<MediaCellEvent, MediaCellState> {
  MediaCellBloc({
    required this.cellController,
  }) : super(MediaCellState.initial(cellController)) {
    _dispatch();
  }

  final MediaCellController cellController;
  void Function()? _onCellChangedFn;

  late UserProfilePB _userProfile;

  UserProfilePB get userProfile => _userProfile;

  String get databaseId => cellController.viewId;

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
            _startListening();

            // Fetch user profile
            final userProfileResult =
                await UserBackendService.getCurrentUserProfile();
            userProfileResult.fold(
              (userProfile) => _userProfile = userProfile,
              (l) => Log.error(l),
            );

            // Fetch the files from cellController
            final data = cellController.getCellData();
            if (data != null) {
              emit(state.copyWith(files: data.files));
            }
          },
          didUpdateCell: (files) {
            emit(state.copyWith(files: files));
          },
          didUpdateField: (fieldName) {
            emit(state.copyWith(fieldName: fieldName));
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
            result.fold((l) => null, (err) => Log.error(err));
          },
          removeFile: (id) async {
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
            if (from < to) {
              to--;
            }

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

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(MediaCellEvent.didUpdateField(fieldInfo.name));
    }
  }
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
    required MediaUploadTypePB uploadType,
    required MediaFileTypePB fileType,
  }) = _AddFile;

  const factory MediaCellEvent.removeFile({
    required String fileId,
  }) = _RemoveFile;

  const factory MediaCellEvent.reorderFiles({
    required int from,
    required int to,
  }) = _ReorderFiles;
}

@freezed
class MediaCellState with _$MediaCellState {
  const factory MediaCellState({
    required String fieldName,
    @Default([]) List<MediaFilePB> files,
  }) = _MediaCellState;

  factory MediaCellState.initial(MediaCellController cellController) {
    return MediaCellState(fieldName: cellController.fieldInfo.field.name);
  }
}

import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'board_actions_bloc.freezed.dart';

class BoardActionsCubit extends Cubit<BoardActionsState> {
  BoardActionsCubit({
    required this.databaseController,
  }) : super(const BoardActionsState.initial());

  final DatabaseController databaseController;

  void startEditingRow(GroupedRowId groupedRowId) {
    emit(BoardActionsState.startEditingRow(groupedRowId: groupedRowId));
    emit(const BoardActionsState.initial());
  }

  void endEditing(GroupedRowId groupedRowId) {
    emit(const BoardActionsState.endEditingRow());
    emit(BoardActionsState.setFocus(groupedRowIds: [groupedRowId]));
    emit(const BoardActionsState.initial());
  }

  void openCard(RowMetaPB rowMeta) {
    emit(BoardActionsState.openCard(rowMeta: rowMeta));
    emit(const BoardActionsState.initial());
  }

  void openCardWithRowId(rowId) {
    final rowMeta = databaseController.rowCache.getRow(rowId)!.rowMeta;
    openCard(rowMeta);
  }

  void setFocus(List<GroupedRowId> groupedRowIds) {
    emit(BoardActionsState.setFocus(groupedRowIds: groupedRowIds));
    emit(const BoardActionsState.initial());
  }

  void startCreateBottomRow(String groupId) {
    emit(BoardActionsState.startCreateBottomRow(groupId: groupId));
    emit(const BoardActionsState.initial());
  }

  void createRow(
    GroupedRowId? groupedRowId,
    CreateBoardCardRelativePosition relativePosition,
  ) {
    emit(
      BoardActionsState.createRow(
        groupedRowId: groupedRowId,
        position: relativePosition,
      ),
    );
    emit(const BoardActionsState.initial());
  }
}

@freezed
class BoardActionsState with _$BoardActionsState {
  const factory BoardActionsState.initial() = _BoardActionsInitialState;

  const factory BoardActionsState.openCard({
    required RowMetaPB rowMeta,
  }) = _BoardActionsOpenCardState;

  const factory BoardActionsState.startEditingRow({
    required GroupedRowId groupedRowId,
  }) = _BoardActionsStartEditingRowState;

  const factory BoardActionsState.endEditingRow() =
      _BoardActionsEndEditingRowState;

  const factory BoardActionsState.setFocus({
    required List<GroupedRowId> groupedRowIds,
  }) = _BoardActionsSetFocusState;

  const factory BoardActionsState.startCreateBottomRow({
    required String groupId,
  }) = _BoardActionsStartCreateBottomRowState;

  const factory BoardActionsState.createRow({
    required GroupedRowId? groupedRowId,
    required CreateBoardCardRelativePosition position,
  }) = _BoardActionCreateRowState;
}

enum CreateBoardCardRelativePosition {
  before,
  after,
}

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_controller.dart';

part 'ungrouped_items_bloc.freezed.dart';

class UngroupedItemsBloc
    extends Bloc<UngroupedItemsEvent, UngroupedItemsState> {
  UngroupedItemsListener? listener;

  UngroupedItemsBloc({required GroupPB group})
      : super(UngroupedItemsState(ungroupedItemsGroup: group)) {
    on<UngroupedItemsEvent>(
      (event, emit) {
        event.when(
          initial: () {
            listener = UngroupedItemsListener(
              group: group,
              onGroupChanged: (group) {
                if (isClosed) return;
                add(UngroupedItemsEvent.updateGroup(group));
              },
            )..startListening();
          },
          updateGroup: (group) {
            emit(state.copyWith(ungroupedItemsGroup: group));
          },
        );
      },
    );
  }
}

@freezed
class UngroupedItemsEvent with _$UngroupedItemsEvent {
  const factory UngroupedItemsEvent.initial() = _Initial;
  const factory UngroupedItemsEvent.updateGroup(GroupPB group) = _UpdateGroup;
}

@freezed
class UngroupedItemsState with _$UngroupedItemsState {
  const factory UngroupedItemsState({required GroupPB ungroupedItemsGroup}) =
      _UngroupedItemsState;
}

class UngroupedItemsListener {
  final GroupPB group;
  final SingleGroupListener _listener;
  final void Function(GroupPB group) onGroupChanged;

  UngroupedItemsListener({
    required this.group,
    required this.onGroupChanged,
  }) : _listener = SingleGroupListener(group);

  void startListening() {
    _listener.start(
      onGroupChanged: (result) {
        result.fold(
          (GroupRowsNotificationPB changeset) {
            for (final deletedRow in changeset.deletedRows) {
              group.rows.removeWhere((rowPB) => rowPB.id == deletedRow);
            }

            for (final insertedRow in changeset.insertedRows) {
              if (insertedRow.hasIndex() &&
                  group.rows.length > insertedRow.index) {
                group.rows.insert(insertedRow.index, insertedRow.rowMeta);
              } else {
                group.rows.add(insertedRow.rowMeta);
              }
            }

            for (final updatedRow in changeset.updatedRows) {
              final index = group.rows.indexWhere(
                (rowPB) => rowPB.id == updatedRow.id,
              );

              if (index != -1) {
                group.rows[index] = updatedRow;
              }
            }
            onGroupChanged.call(group);
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  Future<void> dispose() async {
    _listener.stop();
  }
}

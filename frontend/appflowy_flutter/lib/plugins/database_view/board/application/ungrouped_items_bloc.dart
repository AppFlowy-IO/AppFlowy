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
      : super(UngroupedItemsState(ungroupedItems: group.rows)) {
    on<UngroupedItemsEvent>(
      (event, emit) {
        event.when(
          initial: () {
            listener = UngroupedItemsListener(
              initialGroup: group,
              onGroupChanged: (ungroupedItems) {
                if (isClosed) return;
                add(
                  UngroupedItemsEvent.updateGroup(
                    ungroupedItems: ungroupedItems,
                  ),
                );
              },
            )..startListening();
          },
          updateGroup: (newItems) =>
              emit(UngroupedItemsState(ungroupedItems: newItems)),
        );
      },
    );
  }
}

@freezed
class UngroupedItemsEvent with _$UngroupedItemsEvent {
  const factory UngroupedItemsEvent.initial() = _Initial;
  const factory UngroupedItemsEvent.updateGroup({
    required List<RowMetaPB> ungroupedItems,
  }) = _UpdateGroup;
}

@freezed
class UngroupedItemsState with _$UngroupedItemsState {
  const factory UngroupedItemsState({
    required List<RowMetaPB> ungroupedItems,
  }) = _UngroupedItemsState;
}

class UngroupedItemsListener {
  List<RowMetaPB> _ungroupedItems;
  final SingleGroupListener _listener;
  final void Function(List<RowMetaPB> items) onGroupChanged;

  UngroupedItemsListener({
    required GroupPB initialGroup,
    required this.onGroupChanged,
  })  : _ungroupedItems = List<RowMetaPB>.from(initialGroup.rows),
        _listener = SingleGroupListener(initialGroup);

  void startListening() {
    _listener.start(
      onGroupChanged: (result) {
        result.fold(
          (GroupRowsNotificationPB changeset) {
            final newItems = List<RowMetaPB>.from(_ungroupedItems);
            for (final deletedRow in changeset.deletedRows) {
              newItems.removeWhere((rowPB) => rowPB.id == deletedRow);
            }

            for (final insertedRow in changeset.insertedRows) {
              final index = newItems.indexWhere(
                (rowPB) => rowPB.id == insertedRow.rowMeta.id,
              );
              if (index != -1) {
                continue;
              }
              if (insertedRow.hasIndex() &&
                  newItems.length > insertedRow.index) {
                newItems.insert(insertedRow.index, insertedRow.rowMeta);
              } else {
                newItems.add(insertedRow.rowMeta);
              }
            }

            for (final updatedRow in changeset.updatedRows) {
              final index = newItems.indexWhere(
                (rowPB) => rowPB.id == updatedRow.id,
              );

              if (index != -1) {
                newItems[index] = updatedRow;
              }
            }
            onGroupChanged.call(newItems);
            _ungroupedItems = newItems;
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

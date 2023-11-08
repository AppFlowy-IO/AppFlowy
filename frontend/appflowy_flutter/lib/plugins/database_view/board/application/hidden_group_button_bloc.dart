import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

import 'group_controller.dart';

part 'hidden_group_button_bloc.freezed.dart';

class HiddenGroupButtonBloc
    extends Bloc<HiddenGroupButtonEvent, HiddenGroupButtonState> {
  late final HiddenGroupsListener listener;

  HiddenGroupButtonBloc({required GroupPB group})
      : super(HiddenGroupButtonState(hiddenGroup: group)) {
    on<HiddenGroupButtonEvent>(
      (event, emit) {
        event.when(
          initial: _startListening,
          didUpdateGroup: (GroupPB group) =>
              emit(state.copyWith(hiddenGroup: group)),
        );
      },
    );
  }

  void _startListening() {
    listener = HiddenGroupsListener(
      initialGroup: state.hiddenGroup,
      onGroupChanged: (newGroupItems) {
        final group = state.hiddenGroup;
        group
          ..freeze()
          ..rebuild(
            (g) => g.rows
              ..clear()
              ..addAll(newGroupItems),
          );

        add(HiddenGroupButtonEvent.didUpdateGroup(group: group));
      },
    )..startListening();
  }
}

@freezed
class HiddenGroupButtonEvent with _$HiddenGroupButtonEvent {
  const factory HiddenGroupButtonEvent.initial() = _Initial;
  const factory HiddenGroupButtonEvent.didUpdateGroup({
    required GroupPB group,
  }) = _DidReceiveHiddenGroups;
}

@freezed
class HiddenGroupButtonState with _$HiddenGroupButtonState {
  const factory HiddenGroupButtonState({
    required GroupPB hiddenGroup,
  }) = _HiddenGroupButtonState;
}

class HiddenGroupsListener {
  final SingleGroupListener _listener;
  final void Function(List<RowMetaPB> items) onGroupChanged;
  List<RowMetaPB> _groupItems;

  HiddenGroupsListener({
    required GroupPB initialGroup,
    required this.onGroupChanged,
  })  : _groupItems = List<RowMetaPB>.from(initialGroup.rows),
        _listener = SingleGroupListener(initialGroup);

  void startListening() {
    _listener.start(
      onGroupChanged: (result) => result.fold(
        (GroupRowsNotificationPB changeset) {
          final newItems = List<RowMetaPB>.from(_groupItems);
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

            if (insertedRow.hasIndex() && newItems.length > insertedRow.index) {
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
          _groupItems = newItems;
        },
        (err) => Log.error(err),
      ),
    );
  }

  Future<void> dispose() async => _listener.stop();
}

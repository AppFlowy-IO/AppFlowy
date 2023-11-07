import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

import 'group_controller.dart';

part 'hidden_groups_bloc.freezed.dart';

class HiddenGroupsBloc extends Bloc<HiddenGroupsEvent, HiddenGroupsState> {
  final DatabaseController databaseController;
  Map<String, HiddenGroupsListener> hiddenGroupControllers = {};

  HiddenGroupsBloc({
    required this.databaseController,
    required List<GroupPB> initialHiddenGroups,
  }) : super(HiddenGroupsState(hiddenGroups: initialHiddenGroups)) {
    on<HiddenGroupsEvent>(
      (event, emit) {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveHiddenGroups: (groups) {
            emit(state.copyWith(hiddenGroups: groups));
          },
        );
      },
    );
  }

  void _startListening() {
    databaseController.addListener(
      onGroupChanged: GroupCallbacks(
        onGroupByField: (List<GroupPB> groups) {
          if (isClosed) return;

          hiddenGroupControllers.clear();
          groups.retainWhere((element) => !element.isVisible);
          for (final group in groups) {
            final listener = _makeHiddenGroupListener(group);
            hiddenGroupControllers[group.groupId] = listener;
          }
          add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: groups));
        },
        onUpdateGroup: (List<GroupPB> updatedGroups) {
          if (isClosed) return;

          final newGroups = List<GroupPB>.from(state.hiddenGroups);
          for (final group in updatedGroups) {
            final index = newGroups
                .indexWhere((element) => element.groupId == group.groupId);
            if (index == -1) {
              if (!group.isVisible) {
                newGroups.add(group);
                hiddenGroupControllers[group.groupId] =
                    _makeHiddenGroupListener(group);
              }
            } else {
              newGroups.removeAt(index);
              if (!group.isVisible) {
                newGroups.insert(index, group);
              } else {
                hiddenGroupControllers.remove(group.groupId);
              }
            }
          }
          add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups));
        },
        onDeleteGroup: (List<String> deletedGroupIds) {
          if (isClosed) return;

          final newGroups = state.hiddenGroups;
          for (final id in deletedGroupIds) {
            hiddenGroupControllers.remove(id);
            newGroups.removeWhere((group) => group.groupId == id);
          }
          add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups));
        },
        onInsertGroup: (InsertedGroupPB insertedGroup) {
          if (isClosed) return;

          final group = insertedGroup.group;
          if (!group.isVisible) {
            final newGroups = state.hiddenGroups;
            newGroups.add(group);
            final listener = _makeHiddenGroupListener(group);
            hiddenGroupControllers[group.groupId] = listener;
            add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups));
          }
        },
      ),
    );
  }

  HiddenGroupsListener _makeHiddenGroupListener(GroupPB group) {
    return HiddenGroupsListener(
      initialGroup: group,
      onGroupChanged: ((groupId, items) {
        final newGroups = List<GroupPB>.from(state.hiddenGroups);
        final index = state.hiddenGroups
            .indexWhere((element) => element.groupId == groupId);
        if (index == -1) {
          return;
        }
        final group = newGroups.removeAt(index);
        group.freeze();
        group.rebuild((g) {
          g.rows.clear();
          g.rows.addAll(items);
        });
        newGroups.insert(index, group);
        add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups));
      }),
    );
  }
}

@freezed
class HiddenGroupsEvent with _$HiddenGroupsEvent {
  const factory HiddenGroupsEvent.initial() = _Initial;
  const factory HiddenGroupsEvent.didReceiveHiddenGroups({
    required List<GroupPB> groups,
  }) = _DidReceiveHiddenGroups;
}

@freezed
class HiddenGroupsState with _$HiddenGroupsState {
  const factory HiddenGroupsState({
    required List<GroupPB> hiddenGroups,
  }) = _HiddenGroupsState;
}

class HiddenGroupsListener {
  final String _groupId;
  List<RowMetaPB> _groupItems;
  final SingleGroupListener _listener;
  final void Function(String groupId, List<RowMetaPB> items) onGroupChanged;

  HiddenGroupsListener({
    required GroupPB initialGroup,
    required this.onGroupChanged,
  })  : _groupId = initialGroup.groupId,
        _groupItems = List<RowMetaPB>.from(initialGroup.rows),
        _listener = SingleGroupListener(initialGroup);

  void startListening() {
    _listener.start(
      onGroupChanged: (result) {
        result.fold(
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
            onGroupChanged.call(_groupId, newItems);
            _groupItems = newItems;
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

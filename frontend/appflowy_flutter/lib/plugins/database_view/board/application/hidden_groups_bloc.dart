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
  final List<GroupPB> groups;

  HiddenGroupsBloc({
    required this.databaseController,
    required bool hideUngrouped,
    required List<GroupPB> initialGroups,
  })  : groups = initialGroups,
        super(HiddenGroupsState.initial(hideUngrouped, initialGroups)) {
    on<HiddenGroupsEvent>(
      (event, emit) {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveHiddenGroups: (newGroups) {
            groups.clear();
            groups.addAll(newGroups);
            emit(
              state.copyWith(
                hiddenGroups: _filterHiddenGroups(
                  databaseController
                      .databaseLayoutSetting!.board.hideUngroupedColumn,
                  newGroups,
                ),
              ),
            );
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
          for (final group in groups) {
            final listener = _makeHiddenGroupListener(group);
            hiddenGroupControllers[group.groupId] = listener;
          }
          add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: groups));
        },
        onUpdateGroup: (List<GroupPB> updatedGroups) {
          if (isClosed) return;

          final newGroups = List<GroupPB>.from(groups);
          for (final group in updatedGroups) {
            final index = newGroups
                .indexWhere((element) => element.groupId == group.groupId);
            if (index == -1) {
              continue;
            }
            newGroups.removeAt(index);
            newGroups.insert(index, group);
            hiddenGroupControllers[group.groupId] =
                _makeHiddenGroupListener(group);
          }
          add(
            HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups),
          );
        },
        onDeleteGroup: (List<String> deletedGroupIds) {
          if (isClosed) return;

          final newGroups = List<GroupPB>.from(groups);
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
            final newGroups = List<GroupPB>.from(groups);
            newGroups.insert(insertedGroup.index, group);
            final listener = _makeHiddenGroupListener(group);
            hiddenGroupControllers[group.groupId] = listener;
            add(
              HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups),
            );
          }
        },
      ),
      onLayoutSettingsChanged: DatabaseLayoutSettingCallbacks(
        onLayoutSettingsChanged: (layoutSettings) {
          if (isClosed) return;
          add(
            HiddenGroupsEvent.didReceiveHiddenGroups(
              groups: List<GroupPB>.from(groups),
            ),
          );
        },
      ),
    );
  }

  HiddenGroupsListener _makeHiddenGroupListener(GroupPB group) {
    return HiddenGroupsListener(
      initialGroup: group,
      onGroupChanged: ((groupId, items) {
        final newGroups = List<GroupPB>.from(groups);
        final index =
            newGroups.indexWhere((element) => element.groupId == groupId);
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

  factory HiddenGroupsState.initial(bool hideUngrouped, List<GroupPB> groups) =>
      HiddenGroupsState(
        hiddenGroups: _filterHiddenGroups(hideUngrouped, groups),
      );
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

List<GroupPB> _filterHiddenGroups(bool hideUngrouped, List<GroupPB> groups) {
  final hiddenGroups = List<GroupPB>.from(groups);

  hiddenGroups.retainWhere((group) {
    return !group.isVisible || group.isDefault && hideUngrouped;
  });

  return hiddenGroups;
}

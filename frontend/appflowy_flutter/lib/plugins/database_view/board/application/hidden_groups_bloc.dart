import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hidden_groups_bloc.freezed.dart';

class HiddenGroupsBloc extends Bloc<HiddenGroupsEvent, HiddenGroupsState> {
  final DatabaseController databaseController;
  final List<GroupPB> groups;

  HiddenGroupsBloc({
    required this.databaseController,
    required List<GroupPB> initialGroups,
  })  : groups = initialGroups,
        super(
          HiddenGroupsState.initial(
            databaseController.databaseLayoutSetting!.board.hideUngroupedColumn,
            initialGroups,
          ),
        ) {
    on<HiddenGroupsEvent>(
      (event, emit) {
        event.when(
          initial: _startListening,
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
          }

          add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups));
        },
        onDeleteGroup: (List<String> deletedGroupIds) {
          if (isClosed) return;

          final newGroups = List<GroupPB>.from(groups);
          for (final id in deletedGroupIds) {
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
            add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups));
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

  factory HiddenGroupsState.initial(
    bool hideUngrouped,
    List<GroupPB> groups,
  ) =>
      HiddenGroupsState(
        hiddenGroups: _filterHiddenGroups(
          hideUngrouped,
          groups,
        ),
      );
}

List<GroupPB> _filterHiddenGroups(bool hideUngrouped, List<GroupPB> groups) {
  return List<GroupPB>.from(groups)
    ..retainWhere(
      (group) => !group.isVisible || group.isDefault && hideUngrouped,
    );
}

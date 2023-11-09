import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hidden_groups_bloc.freezed.dart';

class HiddenGroupsBloc extends Bloc<HiddenGroupsEvent, HiddenGroupsState> {
  final DatabaseController databaseController;
  List<GroupPB> _groups;

  HiddenGroupsBloc({
    required this.databaseController,
    required List<GroupPB> initialGroups,
  })  : _groups = initialGroups,
        super(
          HiddenGroupsState.initial(
            databaseController
                    .databaseLayoutSetting?.board.hideUngroupedColumn ??
                false,
            initialGroups,
          ),
        ) {
    on<HiddenGroupsEvent>(
      (event, emit) {
        event.when(
          initial: _startListening,
          didReceiveHiddenGroups: (newGroups) {
            _groups = newGroups;

            final hideUngrouped = databaseController
                    .databaseLayoutSetting?.board.hideUngroupedColumn ??
                false;

            emit(
              state.copyWith(
                hiddenGroups: _filterHiddenGroups(hideUngrouped, newGroups),
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

          final newGroups = [..._groups];
          for (final group in updatedGroups) {
            final index =
                newGroups.indexWhere((g) => g.groupId == group.groupId);
            if (index == -1) {
              continue;
            }

            newGroups.removeAt(index);
            newGroups.add(group);
          }

          add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups));
        },
        onDeleteGroup: (List<String> deletedGroupIds) {
          if (isClosed) return;

          final newGroups = [..._groups];
          for (final id in deletedGroupIds) {
            newGroups.removeWhere((group) => group.groupId == id);
          }

          add(HiddenGroupsEvent.didReceiveHiddenGroups(groups: newGroups));
        },
        onInsertGroup: (InsertedGroupPB insertedGroup) {
          if (isClosed) return;

          final group = insertedGroup.group;
          if (!group.isVisible) {
            final newGroups = [..._groups];
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
              groups: [..._groups],
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
  return [...groups]..retainWhere(
      (group) => !group.isVisible || group.isDefault && hideUngrouped,
    );
}

import 'package:appflowy/plugins/database/board/group_ext.dart';
import 'package:appflowy/plugins/database/domain/group_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../application/database_controller.dart';
import '../../application/field/field_controller.dart';

part 'column_header_bloc.freezed.dart';

class ColumnHeaderBloc extends Bloc<ColumnHeaderEvent, ColumnHeaderState> {
  ColumnHeaderBloc({
    required this.databaseController,
    required this.fieldId,
    required this.group,
  }) : super(const ColumnHeaderState.loading()) {
    groupBackendSvc = GroupBackendService(viewId);
    _dispatch();
  }

  final DatabaseController databaseController;
  final String fieldId;
  final GroupPB group;

  late final GroupBackendService groupBackendSvc;

  FieldController get fieldController => databaseController.fieldController;
  String get viewId => databaseController.viewId;

  void _dispatch() {
    on<ColumnHeaderEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            final name = group.generateGroupName(databaseController);
            emit(ColumnHeaderState.initial(name));
          },
          startEditing: () async {
            state.maybeMap(
              ready: (state) => emit(state.copyWith(isEditing: true)),
              orElse: () {},
            );
          },
          endEditing: (String? groupName) async {
            if (groupName != null) {
              final stateGroupName = state.maybeMap(
                ready: (state) => state.groupName,
                orElse: () => null,
              );

              if (stateGroupName == null || stateGroupName == groupName) {
                state.maybeMap(
                  ready: (state) => emit(
                    state.copyWith(
                      groupName: stateGroupName!,
                      isEditing: false,
                    ),
                  ),
                  orElse: () {},
                );
              }

              await groupBackendSvc.renameGroup(
                groupId: group.groupId,
                fieldId: fieldId,
                name: groupName,
              );
              state.maybeMap(
                ready: (state) {
                  emit(state.copyWith(groupName: groupName, isEditing: false));
                },
                orElse: () {},
              );
            }
          },
        );
      },
    );
  }
}

@freezed
class ColumnHeaderEvent with _$ColumnHeaderEvent {
  const factory ColumnHeaderEvent.initial() = _Initial;
  const factory ColumnHeaderEvent.startEditing() = _StartEditing;
  const factory ColumnHeaderEvent.endEditing(String? groupName) = _EndEditing;
}

@freezed
class ColumnHeaderState with _$ColumnHeaderState {
  const ColumnHeaderState._();

  const factory ColumnHeaderState.loading() = _ColumnHeaderLoadingState;

  const factory ColumnHeaderState.error({
    required FlowyError error,
  }) = _ColumnHeaderErrorState;

  const factory ColumnHeaderState.ready({
    required String groupName,
    @Default(false) bool isEditing,
    @Default(false) bool canEdit,
  }) = _ColumnHeaderReadyState;

  factory ColumnHeaderState.initial(String name) =>
      ColumnHeaderState.ready(groupName: name);

  bool get isLoading => maybeMap(loading: (_) => true, orElse: () => false);
  bool get isError => maybeMap(error: (_) => true, orElse: () => false);
  bool get isReady => maybeMap(ready: (_) => true, orElse: () => false);
}

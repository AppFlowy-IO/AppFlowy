import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_filter_editor_bloc.freezed.dart';

class ChecklistFilterBloc
    extends Bloc<ChecklistFilterEvent, ChecklistFilterState> {
  ChecklistFilterBloc({
    required this.fieldController,
    required FilterInfo filterInfo,
  })  : filterId = filterInfo.filterId,
        fieldId = filterInfo.fieldId,
        _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(ChecklistFilterState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final FieldController fieldController;
  final String filterId;
  final String fieldId;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void Function(FieldInfo)? _onFieldChanged;

  void _dispatch() {
    on<ChecklistFilterEvent>(
      (event, emit) async {
        await event.when(
          updateCondition: (ChecklistFilterConditionPB condition) {
            return _filterBackendSvc.insertChecklistFilter(
              filterId: filterId,
              fieldId: fieldId,
              condition: condition,
            );
          },
          didReceiveFilter: (filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            final checklistFilter = filterInfo.checklistFilter()!;
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: checklistFilter,
              ),
            );
          },
          didReceiveField: (field) {
            final filterInfo = state.filterInfo.copyWith(fieldInfo: field);
            emit(
              state.copyWith(
                filterInfo: filterInfo,
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onUpdated: (filter) {
        if (!isClosed) {
          add(ChecklistFilterEvent.didReceiveFilter(filter));
        }
      },
    );
    _onFieldChanged = (field) {
      if (!isClosed) {
        add(ChecklistFilterEvent.didReceiveField(field));
      }
    };
    fieldController.addSingleFieldListener(
      fieldId,
      onFieldChanged: _onFieldChanged!,
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    if (_onFieldChanged != null) {
      fieldController.removeSingleFieldListener(
        fieldId: fieldId,
        onFieldChanged: _onFieldChanged!,
      );
    }
    return super.close();
  }
}

@freezed
class ChecklistFilterEvent with _$ChecklistFilterEvent {
  const factory ChecklistFilterEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory ChecklistFilterEvent.didReceiveField(
    FieldInfo field,
  ) = _DidReceiveField;
  const factory ChecklistFilterEvent.updateCondition(
    ChecklistFilterConditionPB condition,
  ) = _UpdateCondition;
}

@freezed
class ChecklistFilterState with _$ChecklistFilterState {
  const factory ChecklistFilterState({
    required FilterInfo filterInfo,
    required ChecklistFilterPB filter,
  }) = _ChecklistFilterState;

  factory ChecklistFilterState.initial(FilterInfo filterInfo) {
    return ChecklistFilterState(
      filterInfo: filterInfo,
      filter: filterInfo.checklistFilter()!,
    );
  }
}

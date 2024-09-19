import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkbox_filter_editor_bloc.freezed.dart';

class CheckboxFilterBloc
    extends Bloc<CheckboxFilterEvent, CheckboxFilterState> {
  CheckboxFilterBloc({
    required this.fieldController,
    required FilterInfo filterInfo,
  })  : filterId = filterInfo.filterId,
        fieldId = filterInfo.fieldId,
        _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filterId,
        ),
        super(CheckboxFilterState.initial(filterInfo)) {
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
    on<CheckboxFilterEvent>(
      (event, emit) async {
        await event.when(
          updateCondition: (condition) {
            return _filterBackendSvc.insertCheckboxFilter(
              filterId: filterId,
              fieldId: fieldId,
              condition: condition,
            );
          },
          didReceiveFilter: (filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            final checkboxFilter = filterInfo.checkboxFilter()!;
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: checkboxFilter,
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
          add(CheckboxFilterEvent.didReceiveFilter(filter));
        }
      },
    );
    _onFieldChanged = (field) {
      if (!isClosed) {
        add(CheckboxFilterEvent.didReceiveField(field));
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
class CheckboxFilterEvent with _$CheckboxFilterEvent {
  const factory CheckboxFilterEvent.didReceiveFilter(
    FilterPB filter,
  ) = _DidReceiveFilter;
  const factory CheckboxFilterEvent.didReceiveField(
    FieldInfo field,
  ) = _DidReceiveField;
  const factory CheckboxFilterEvent.updateCondition(
    CheckboxFilterConditionPB condition,
  ) = _UpdateCondition;
}

@freezed
class CheckboxFilterState with _$CheckboxFilterState {
  const factory CheckboxFilterState({
    required FilterInfo filterInfo,
    required CheckboxFilterPB filter,
  }) = _CheckboxFilterState;

  factory CheckboxFilterState.initial(FilterInfo filterInfo) {
    return CheckboxFilterState(
      filterInfo: filterInfo,
      filter: filterInfo.checkboxFilter()!,
    );
  }
}

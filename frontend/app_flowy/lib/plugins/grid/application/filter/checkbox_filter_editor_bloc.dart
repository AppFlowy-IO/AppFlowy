import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'filter_listener.dart';
import 'filter_service.dart';

part 'checkbox_filter_editor_bloc.freezed.dart';

class CheckboxFilterEditorBloc
    extends Bloc<CheckboxFilterEditorEvent, CheckboxFilterEditorState> {
  final FilterInfo filterInfo;
  final FilterFFIService _ffiService;
  final FilterListener _listener;

  CheckboxFilterEditorBloc({required this.filterInfo})
      : _ffiService = FilterFFIService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(CheckboxFilterEditorState.initial(filterInfo)) {
    on<CheckboxFilterEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          updateCondition: (CheckboxFilterCondition condition) {
            _ffiService.insertCheckboxFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
            );
          },
          delete: () {
            _ffiService.deleteFilter(
              fieldId: filterInfo.fieldInfo.id,
              filterId: filterInfo.filter.id,
              fieldType: filterInfo.fieldInfo.fieldType,
            );
          },
          didReceiveFilter: (FilterPB filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            final checkboxFilter = filterInfo.checkboxFilter()!;
            emit(state.copyWith(
              filterInfo: filterInfo,
              filter: checkboxFilter,
            ));
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onDeleted: () {
        if (!isClosed) add(const CheckboxFilterEditorEvent.delete());
      },
      onUpdated: (filter) {
        if (!isClosed) add(CheckboxFilterEditorEvent.didReceiveFilter(filter));
      },
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }
}

@freezed
class CheckboxFilterEditorEvent with _$CheckboxFilterEditorEvent {
  const factory CheckboxFilterEditorEvent.initial() = _Initial;
  const factory CheckboxFilterEditorEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory CheckboxFilterEditorEvent.updateCondition(
      CheckboxFilterCondition condition) = _UpdateCondition;
  const factory CheckboxFilterEditorEvent.delete() = _Delete;
}

@freezed
class CheckboxFilterEditorState with _$CheckboxFilterEditorState {
  const factory CheckboxFilterEditorState({
    required FilterInfo filterInfo,
    required CheckboxFilterPB filter,
  }) = _GridFilterState;

  factory CheckboxFilterEditorState.initial(FilterInfo filterInfo) {
    return CheckboxFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.checkboxFilter()!,
    );
  }
}

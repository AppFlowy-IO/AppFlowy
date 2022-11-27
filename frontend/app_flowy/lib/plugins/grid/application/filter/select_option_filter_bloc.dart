import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option_filter.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'filter_listener.dart';
import 'filter_service.dart';

part 'select_option_filter_bloc.freezed.dart';

class SelectOptionFilterEditorBloc
    extends Bloc<SelectOpitonFilterEditorEvent, SelectOptionFilterEditorState> {
  final FilterInfo filterInfo;
  final FilterFFIService _ffiService;
  final FilterListener _listener;

  SelectOptionFilterEditorBloc({required this.filterInfo})
      : _ffiService = FilterFFIService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(SelectOptionFilterEditorState.initial(filterInfo)) {
    on<SelectOpitonFilterEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          updateCondition: (SelectOptionCondition condition) {
            _ffiService.insertSelectOptionFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.field.id,
              condition: condition,
              optionIds: state.filter.optionIds,
              fieldType: state.filterInfo.field.fieldType,
            );
          },
          updateContent: (List<String> optionIds) {
            _ffiService.insertSelectOptionFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.field.id,
              condition: state.filter.condition,
              optionIds: optionIds,
              fieldType: state.filterInfo.field.fieldType,
            );
          },
          delete: () {
            _ffiService.deleteFilter(
              fieldId: filterInfo.field.id,
              filterId: filterInfo.filter.id,
              fieldType: filterInfo.field.fieldType,
            );
          },
          didReceiveFilter: (FilterPB filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            final selectOptionFilter = filterInfo.selectOptionFilter()!;
            emit(state.copyWith(
              filterInfo: filterInfo,
              filter: selectOptionFilter,
            ));
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onDeleted: () {
        if (!isClosed) add(const SelectOpitonFilterEditorEvent.delete());
      },
      onUpdated: (filter) {
        if (!isClosed) {
          add(SelectOpitonFilterEditorEvent.didReceiveFilter(filter));
        }
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
class SelectOpitonFilterEditorEvent with _$SelectOpitonFilterEditorEvent {
  const factory SelectOpitonFilterEditorEvent.initial() = _Initial;
  const factory SelectOpitonFilterEditorEvent.didReceiveFilter(
      FilterPB filter) = _DidReceiveFilter;
  const factory SelectOpitonFilterEditorEvent.updateCondition(
      SelectOptionCondition condition) = _UpdateCondition;
  const factory SelectOpitonFilterEditorEvent.updateContent(
      List<String> optionIds) = _UpdateContent;
  const factory SelectOpitonFilterEditorEvent.delete() = _Delete;
}

@freezed
class SelectOptionFilterEditorState with _$SelectOptionFilterEditorState {
  const factory SelectOptionFilterEditorState({
    required FilterInfo filterInfo,
    required SelectOptionFilterPB filter,
  }) = _GridFilterState;

  factory SelectOptionFilterEditorState.initial(FilterInfo filterInfo) {
    return SelectOptionFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.selectOptionFilter()!,
    );
  }
}

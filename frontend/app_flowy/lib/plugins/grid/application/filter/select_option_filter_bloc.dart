import 'package:app_flowy/plugins/grid/presentation/widgets/filter/choicechip/select_option/select_option_loader.dart';
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
    extends Bloc<SelectOptionFilterEditorEvent, SelectOptionFilterEditorState> {
  final FilterInfo filterInfo;
  final FilterFFIService _ffiService;
  final FilterListener _listener;
  final SelectOptionFilterDelegate delegate;

  SelectOptionFilterEditorBloc({
    required this.filterInfo,
    required this.delegate,
  })  : _ffiService = FilterFFIService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(SelectOptionFilterEditorState.initial(filterInfo)) {
    on<SelectOptionFilterEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
            _loadOptions();
          },
          updateCondition: (SelectOptionConditionPB condition) {
            _ffiService.insertSelectOptionFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
              optionIds: state.filter.optionIds,
              fieldType: state.filterInfo.fieldInfo.fieldType,
            );
          },
          updateContent: (List<String> optionIds) {
            _ffiService.insertSelectOptionFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: state.filter.condition,
              optionIds: optionIds,
              fieldType: state.filterInfo.fieldInfo.fieldType,
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
            final selectOptionFilter = filterInfo.selectOptionFilter()!;
            emit(state.copyWith(
              filterInfo: filterInfo,
              filter: selectOptionFilter,
            ));
          },
          updateFilterDescription: (String desc) {
            emit(state.copyWith(filterDesc: desc));
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onDeleted: () {
        if (!isClosed) add(const SelectOptionFilterEditorEvent.delete());
      },
      onUpdated: (filter) {
        if (!isClosed) {
          add(SelectOptionFilterEditorEvent.didReceiveFilter(filter));
        }
      },
    );
  }

  void _loadOptions() {
    delegate.loadOptions().then((options) {
      if (!isClosed) {
        String filterDesc = '';
        for (final option in options) {
          if (state.filter.optionIds.contains(option.id)) {
            filterDesc += "${option.name} ";
          }
        }
        add(SelectOptionFilterEditorEvent.updateFilterDescription(filterDesc));
      }
    });
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }
}

@freezed
class SelectOptionFilterEditorEvent with _$SelectOptionFilterEditorEvent {
  const factory SelectOptionFilterEditorEvent.initial() = _Initial;
  const factory SelectOptionFilterEditorEvent.didReceiveFilter(
      FilterPB filter) = _DidReceiveFilter;
  const factory SelectOptionFilterEditorEvent.updateCondition(
      SelectOptionConditionPB condition) = _UpdateCondition;
  const factory SelectOptionFilterEditorEvent.updateContent(
      List<String> optionIds) = _UpdateContent;
  const factory SelectOptionFilterEditorEvent.updateFilterDescription(
      String desc) = _UpdateDesc;
  const factory SelectOptionFilterEditorEvent.delete() = _Delete;
}

@freezed
class SelectOptionFilterEditorState with _$SelectOptionFilterEditorState {
  const factory SelectOptionFilterEditorState({
    required FilterInfo filterInfo,
    required SelectOptionFilterPB filter,
    required String filterDesc,
  }) = _GridFilterState;

  factory SelectOptionFilterEditorState.initial(FilterInfo filterInfo) {
    return SelectOptionFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.selectOptionFilter()!,
      filterDesc: '',
    );
  }
}

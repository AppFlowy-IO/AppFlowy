import 'dart:async';

import 'package:appflowy/plugins/database_view/application/filter/filter_listener.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_service.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_filter_editor_bloc.freezed.dart';

class TextFilterEditorBloc
    extends Bloc<TextFilterEditorEvent, TextFilterEditorState> {
  final String viewId;
  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  TextFilterEditorBloc({required this.viewId, required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: viewId),
        _listener = FilterListener(
          viewId: viewId,
          filterId: filterInfo.filter.id,
        ),
        super(TextFilterEditorState.initial(filterInfo)) {
    on<TextFilterEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          updateCondition: (TextFilterConditionPB condition) {
            _filterBackendSvc.insertTextFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldId,
              condition: condition,
              content: state.filter.content,
            );
          },
          updateContent: (content) {
            _filterBackendSvc.insertTextFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldId,
              condition: state.filter.condition,
              content: content,
            );
          },
          delete: () {
            _filterBackendSvc.deleteFilter(
              fieldId: filterInfo.fieldId,
              filterId: filterInfo.filter.id,
              fieldType: filterInfo.field.fieldType,
            );
          },
          didReceiveFilter: (FilterPB filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            final textFilter = filterInfo.textFilter()!;
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: textFilter,
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onDeleted: () {
        if (!isClosed) add(const TextFilterEditorEvent.delete());
      },
      onUpdated: (filter) {
        if (!isClosed) add(TextFilterEditorEvent.didReceiveFilter(filter));
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
class TextFilterEditorEvent with _$TextFilterEditorEvent {
  const factory TextFilterEditorEvent.initial() = _Initial;
  const factory TextFilterEditorEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory TextFilterEditorEvent.updateCondition(
    TextFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory TextFilterEditorEvent.updateContent(String content) =
      _UpdateContent;
  const factory TextFilterEditorEvent.delete() = _Delete;
}

@freezed
class TextFilterEditorState with _$TextFilterEditorState {
  const factory TextFilterEditorState({
    required FilterInfo filterInfo,
    required TextFilterPB filter,
  }) = _GridFilterState;

  factory TextFilterEditorState.initial(FilterInfo filterInfo) {
    return TextFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.textFilter()!,
    );
  }
}

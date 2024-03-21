import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_filter_editor_bloc.freezed.dart';

class TextFilterEditorBloc
    extends Bloc<TextFilterEditorEvent, TextFilterEditorState> {
  TextFilterEditorBloc({required this.filterInfo, required this.fieldType})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(TextFilterEditorState.initial(filterInfo)) {
    _dispatch();
  }

  final FilterInfo filterInfo;
  final FieldType fieldType;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<TextFilterEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          updateCondition: (TextFilterConditionPB condition) {
            fieldType == FieldType.RichText
                ? _filterBackendSvc.insertTextFilter(
                    filterId: filterInfo.filter.id,
                    fieldId: filterInfo.fieldInfo.id,
                    condition: condition,
                    content: state.filter.content,
                  )
                : _filterBackendSvc.insertURLFilter(
                    filterId: filterInfo.filter.id,
                    fieldId: filterInfo.fieldInfo.id,
                    condition: condition,
                    content: state.filter.content,
                  );
          },
          updateContent: (String content) {
            fieldType == FieldType.RichText
                ? _filterBackendSvc.insertTextFilter(
                    filterId: filterInfo.filter.id,
                    fieldId: filterInfo.fieldInfo.id,
                    condition: state.filter.condition,
                    content: content,
                  )
                : _filterBackendSvc.insertURLFilter(
                    filterId: filterInfo.filter.id,
                    fieldId: filterInfo.fieldInfo.id,
                    condition: state.filter.condition,
                    content: content,
                  );
          },
          delete: () {
            _filterBackendSvc.deleteFilter(
              fieldId: filterInfo.fieldInfo.id,
              filterId: filterInfo.filter.id,
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
      onUpdated: (filter) {
        if (!isClosed) {
          add(TextFilterEditorEvent.didReceiveFilter(filter));
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

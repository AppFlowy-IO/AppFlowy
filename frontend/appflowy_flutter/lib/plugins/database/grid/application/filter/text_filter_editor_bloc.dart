import 'dart:async';

import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_filter_editor_bloc.freezed.dart';

class TextFilterBloc extends Bloc<TextFilterEvent, TextFilterState> {
  TextFilterBloc({required this.filterInfo, required this.fieldType})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(TextFilterState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final FilterInfo filterInfo;
  final FieldType fieldType;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void _dispatch() {
    on<TextFilterEvent>(
      (event, emit) async {
        event.when(
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
          add(TextFilterEvent.didReceiveFilter(filter));
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
class TextFilterEvent with _$TextFilterEvent {
  const factory TextFilterEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory TextFilterEvent.updateCondition(
    TextFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory TextFilterEvent.updateContent(String content) = _UpdateContent;
}

@freezed
class TextFilterState with _$TextFilterState {
  const factory TextFilterState({
    required FilterInfo filterInfo,
    required TextFilterPB filter,
  }) = _TextFilterState;

  factory TextFilterState.initial(FilterInfo filterInfo) {
    return TextFilterState(
      filterInfo: filterInfo,
      filter: filterInfo.textFilter()!,
    );
  }
}

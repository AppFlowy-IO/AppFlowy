import 'package:appflowy/plugins/database_view/application/filter/filter_listener.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database/text_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'text_filter_editor_bloc.freezed.dart';

class TextFilterEditorBloc
    extends Bloc<TextFilterEditorEvent, TextFilterEditorState> {
  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  TextFilterEditorBloc({required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(TextFilterEditorState.initial(filterInfo)) {
    on<TextFilterEditorEvent>(
      (final event, final emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          updateCondition: (final TextFilterConditionPB condition) {
            _filterBackendSvc.insertTextFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
              content: state.filter.content,
            );
          },
          updateContent: (final content) {
            _filterBackendSvc.insertTextFilter(
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
              fieldType: filterInfo.fieldInfo.fieldType,
            );
          },
          didReceiveFilter: (final FilterPB filter) {
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
      onUpdated: (final filter) {
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
  const factory TextFilterEditorEvent.didReceiveFilter(final FilterPB filter) =
      _DidReceiveFilter;
  const factory TextFilterEditorEvent.updateCondition(
    final TextFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory TextFilterEditorEvent.updateContent(final String content) =
      _UpdateContent;
  const factory TextFilterEditorEvent.delete() = _Delete;
}

@freezed
class TextFilterEditorState with _$TextFilterEditorState {
  const factory TextFilterEditorState({
    required final FilterInfo filterInfo,
    required final TextFilterPB filter,
  }) = _GridFilterState;

  factory TextFilterEditorState.initial(final FilterInfo filterInfo) {
    return TextFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.textFilter()!,
    );
  }
}

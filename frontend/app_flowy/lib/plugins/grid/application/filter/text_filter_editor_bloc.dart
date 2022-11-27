import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'filter_listener.dart';
import 'filter_service.dart';

part 'text_filter_editor_bloc.freezed.dart';

class TextFilterEditorBloc
    extends Bloc<TextFilterEditorEvent, TextFilterEditorState> {
  final FilterInfo filterInfo;
  final FilterFFIService _ffiService;
  final FilterListener _listener;

  TextFilterEditorBloc({required this.filterInfo})
      : _ffiService = FilterFFIService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(TextFilterEditorState.initial(filterInfo)) {
    on<TextFilterEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          updateCondition: (TextFilterCondition condition) {
            final textFilter = filterInfo.textFilter()!;
            _ffiService.insertTextFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.field.id,
              condition: condition,
              content: textFilter.content,
            );
          },
          updateContent: (content) {
            final textFilter = filterInfo.textFilter();
            if (textFilter != null) {
              _ffiService.insertTextFilter(
                filterId: filterInfo.filter.id,
                fieldId: filterInfo.field.id,
                condition: textFilter.condition,
                content: content,
              );
            } else {
              Log.error("Invalid text filter");
            }
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
            emit(state.copyWith(
              filterInfo: filterInfo,
              filter: filterInfo.textFilter()!,
            ));
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
      TextFilterCondition condition) = _UpdateCondition;
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

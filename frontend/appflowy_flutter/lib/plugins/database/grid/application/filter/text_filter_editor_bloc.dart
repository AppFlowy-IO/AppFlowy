import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_filter_editor_bloc.freezed.dart';

class TextFilterBloc extends Bloc<TextFilterEvent, TextFilterState> {
  TextFilterBloc({
    required this.fieldController,
    required FilterInfo filterInfo,
    required this.fieldType,
  })  : filterId = filterInfo.filterId,
        fieldId = filterInfo.fieldId,
        _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(TextFilterState.initial(filterInfo)) {
    _dispatch();
    _startListening();
  }

  final FieldController fieldController;
  final String filterId;
  final String fieldId;
  final FieldType fieldType;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  void Function(FieldInfo)? _onFieldChanged;

  void _dispatch() {
    on<TextFilterEvent>(
      (event, emit) async {
        event.when(
          updateCondition: (TextFilterConditionPB condition) {
            fieldType == FieldType.RichText
                ? _filterBackendSvc.insertTextFilter(
                    filterId: filterId,
                    fieldId: fieldId,
                    condition: condition,
                    content: state.filter.content,
                  )
                : _filterBackendSvc.insertURLFilter(
                    filterId: filterId,
                    fieldId: fieldId,
                    condition: condition,
                    content: state.filter.content,
                  );
          },
          updateContent: (String content) {
            fieldType == FieldType.RichText
                ? _filterBackendSvc.insertTextFilter(
                    filterId: filterId,
                    fieldId: fieldId,
                    condition: state.filter.condition,
                    content: content,
                  )
                : _filterBackendSvc.insertURLFilter(
                    filterId: filterId,
                    fieldId: fieldId,
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
          add(TextFilterEvent.didReceiveFilter(filter));
        }
      },
    );
    _onFieldChanged = (field) {
      if (!isClosed) {
        add(TextFilterEvent.didReceiveField(field));
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
class TextFilterEvent with _$TextFilterEvent {
  const factory TextFilterEvent.didReceiveFilter(FilterPB filter) =
      _DidReceiveFilter;
  const factory TextFilterEvent.didReceiveField(
    FieldInfo field,
  ) = _DidReceiveField;
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

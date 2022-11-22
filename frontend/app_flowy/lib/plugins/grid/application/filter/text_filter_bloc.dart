import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'filter_service.dart';

part 'text_filter_bloc.freezed.dart';

class TextFilterBloc extends Bloc<TextFilterEvent, TextFilterState> {
  final String viewId;
  final FilterFFIService _ffiService;
  TextFilterBloc({required this.viewId, required FilterPB filter})
      : _ffiService = FilterFFIService(viewId: viewId),
        super(TextFilterState.initial(filter)) {
    on<TextFilterEvent>(
      (event, emit) async {
        event.when(
          initial: () async {},
          updateCondition: (TextFilterCondition condition) {},
          updateContent: (String content) {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class TextFilterEvent with _$TextFilterEvent {
  const factory TextFilterEvent.initial() = _Initial;
  const factory TextFilterEvent.updateCondition(TextFilterCondition condition) =
      _UpdateCondition;
  const factory TextFilterEvent.updateContent(String content) = _UpdateContent;
}

@freezed
class TextFilterState with _$TextFilterState {
  const factory TextFilterState({
    required FilterPB filter,
  }) = _GridFilterState;

  factory TextFilterState.initial(FilterPB filter) {
    return TextFilterState(
      filter: filter,
    );
  }
}

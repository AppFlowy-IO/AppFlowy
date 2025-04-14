import 'dart:async';

import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result_list_bloc.freezed.dart';

class SearchResultListBloc
    extends Bloc<SearchResultListEvent, SearchResultListState> {
  SearchResultListBloc() : super(SearchResultListState.initial()) {
    // Register event handlers
    on<_OnHoverSummary>(_onHoverSummary);
    on<_OnHoverResult>(_onHoverResult);
    on<_OpenPage>(_onOpenPage);
  }

  FutureOr<void> _onHoverSummary(
    _OnHoverSummary event,
    Emitter<SearchResultListState> emit,
  ) {
    emit(
      state.copyWith(
        hoveredSummary: event.summary,
        hoveredResult: null,
        openPageId: null,
      ),
    );
  }

  FutureOr<void> _onHoverResult(
    _OnHoverResult event,
    Emitter<SearchResultListState> emit,
  ) {
    emit(
      state.copyWith(
        hoveredSummary: null,
        hoveredResult: event.item,
        openPageId: null,
      ),
    );
  }

  FutureOr<void> _onOpenPage(
    _OpenPage event,
    Emitter<SearchResultListState> emit,
  ) {
    emit(state.copyWith(openPageId: event.pageId));
  }
}

@freezed
class SearchResultListEvent with _$SearchResultListEvent {
  const factory SearchResultListEvent.onHoverSummary({
    required SearchSummaryPB summary,
  }) = _OnHoverSummary;
  const factory SearchResultListEvent.onHoverResult({
    required SearchResultItem item,
  }) = _OnHoverResult;

  const factory SearchResultListEvent.openPage({
    required String pageId,
  }) = _OpenPage;
}

@freezed
class SearchResultListState with _$SearchResultListState {
  const SearchResultListState._();
  const factory SearchResultListState({
    @Default(null) SearchSummaryPB? hoveredSummary,
    @Default(null) SearchResultItem? hoveredResult,
    @Default(null) String? openPageId,
  }) = _SearchResultListState;

  factory SearchResultListState.initial() => const SearchResultListState();
}

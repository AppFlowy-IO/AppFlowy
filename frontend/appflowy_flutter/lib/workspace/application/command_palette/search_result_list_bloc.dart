import 'dart:async';

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
  }

  FutureOr<void> _onHoverSummary(
    _OnHoverSummary event,
    Emitter<SearchResultListState> emit,
  ) {
    emit(
      state.copyWith(
        hoveredSummary: event.summary,
        hoveredResult: null,
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
      ),
    );
  }
}

@freezed
class SearchResultListEvent with _$SearchResultListEvent {
  const factory SearchResultListEvent.onHoverSummary({
    required SearchSummaryPB summary,
  }) = _OnHoverSummary;
  const factory SearchResultListEvent.onHoverResult({
    required SearchResponseItemPB item,
  }) = _OnHoverResult;
}

@freezed
class SearchResultListState with _$SearchResultListState {
  const SearchResultListState._();
  const factory SearchResultListState({
    @Default(null) SearchSummaryPB? hoveredSummary,
    @Default(null) SearchResponseItemPB? hoveredResult,
  }) = _SearchResultListState;

  factory SearchResultListState.initial() => const SearchResultListState();
}

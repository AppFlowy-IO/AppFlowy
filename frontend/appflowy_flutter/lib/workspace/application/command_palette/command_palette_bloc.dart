import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:appflowy/workspace/application/command_palette/search_listener.dart';
import 'package:appflowy/workspace/application/command_palette/search_service.dart';
import 'package:appflowy_backend/protobuf/flowy-search/entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_palette_bloc.freezed.dart';

class CommandPaletteBloc
    extends Bloc<CommandPaletteEvent, CommandPaletteState> {
  CommandPaletteBloc() : super(CommandPaletteState.initial()) {
    _searchListener.start(
      onResultsChanged: _onResultsChanged,
      onResultsClosed: _onResultsClosed,
    );

    _dispatch();
  }

  Timer? _debounceOnChanged;
  final SearchListener _searchListener = SearchListener();
  String? _oldQuery;

  @override
  Future<void> close() {
    _searchListener.stop();
    return super.close();
  }

  void _dispatch() {
    on<CommandPaletteEvent>((event, emit) async {
      event.when(
        searchChanged: _debounceOnSearchChanged,
        performSearch: (search) async {
          if (search.isNotEmpty) {
            _oldQuery = state.query;
            emit(state.copyWith(query: search, isLoading: true));
            await SearchBackendService.performSearch(search);
          } else {
            emit(state.copyWith(query: null, isLoading: false, results: []));
          }
        },
        resultsChanged: (results, didClose) {
          if (state.query != _oldQuery) {
            emit(state.copyWith(results: []));
          }

          final searchResults = _filterDuplicates(results.items);
          searchResults.sort((a, b) => b.score.compareTo(a.score));

          emit(
            state.copyWith(
              results: searchResults,
              isLoading: !didClose,
            ),
          );
        },
      );
    });
  }

  void _debounceOnSearchChanged(String value) {
    _debounceOnChanged?.cancel();
    _debounceOnChanged = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(value),
    );
  }

  List<SearchResultPB> _filterDuplicates(List<SearchResultPB> results) {
    final currentItems = [...state.results];
    final res = [...results];

    for (final item in results) {
      final duplicateIndex = currentItems.indexWhere((a) => a.id == item.id);
      if (duplicateIndex == -1) {
        continue;
      }

      final duplicate = currentItems[duplicateIndex];
      if (item.score < duplicate.score) {
        res.remove(item);
      } else {
        currentItems.remove(duplicate);
      }
    }

    return res..addAll(currentItems);
  }

  void _performSearch(String value) =>
      add(CommandPaletteEvent.performSearch(search: value));

  void _onResultsChanged(RepeatedSearchResultPB results) =>
      add(CommandPaletteEvent.resultsChanged(results: results));

  void _onResultsClosed(RepeatedSearchResultPB results) =>
      add(CommandPaletteEvent.resultsChanged(results: results, didClose: true));
}

@freezed
class CommandPaletteEvent with _$CommandPaletteEvent {
  const factory CommandPaletteEvent.searchChanged({required String search}) =
      _SearchChanged;

  const factory CommandPaletteEvent.performSearch({required String search}) =
      _PerformSearch;

  const factory CommandPaletteEvent.resultsChanged({
    required RepeatedSearchResultPB results,
    @Default(false) bool didClose,
  }) = _ResultsChanged;
}

@freezed
class CommandPaletteState with _$CommandPaletteState {
  const CommandPaletteState._();

  const factory CommandPaletteState({
    @Default(null) String? query,
    required List<SearchResultPB> results,
    required bool isLoading,
  }) = _CommandPaletteState;

  factory CommandPaletteState.initial() =>
      const CommandPaletteState(results: [], isLoading: false);
}

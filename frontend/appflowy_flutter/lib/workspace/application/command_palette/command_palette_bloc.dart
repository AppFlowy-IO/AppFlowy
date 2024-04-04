import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:appflowy/plugins/trash/application/trash_listener.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/command_palette/search_listener.dart';
import 'package:appflowy/workspace/application/command_palette/search_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
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

    _initTrash();
    _dispatch();
  }

  Timer? _debounceOnChanged;
  final TrashService _trashService = TrashService();
  final SearchListener _searchListener = SearchListener();
  final TrashListener _trashListener = TrashListener();
  String? _oldQuery;

  @override
  Future<void> close() {
    _trashListener.close();
    _searchListener.stop();
    return super.close();
  }

  void _dispatch() {
    on<CommandPaletteEvent>((event, emit) async {
      event.when(
        searchChanged: _debounceOnSearchChanged,
        trashChanged: (trash) async {
          if (trash != null) {
            emit(state.copyWith(trash: trash));
            return;
          }

          final trashOrFailure = await _trashService.readTrash();
          final trashRes = trashOrFailure.fold(
            (trash) => trash,
            (error) => null,
          );

          if (trashRes != null) {
            emit(state.copyWith(trash: trashRes.items));
          }
        },
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

  Future<void> _initTrash() async {
    _trashListener.start(
      trashUpdated: (trashOrFailed) {
        final trash = trashOrFailed.fold(
          (trash) => trash,
          (error) => null,
        );

        add(CommandPaletteEvent.trashChanged(trash: trash));
      },
    );

    final trashOrFailure = await _trashService.readTrash();
    final trashRes = trashOrFailure.fold(
      (trash) => trash,
      (error) => null,
    );

    add(CommandPaletteEvent.trashChanged(trash: trashRes?.items));
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

  const factory CommandPaletteEvent.trashChanged({
    @Default(null) List<TrashPB>? trash,
  }) = _TrashChanged;
}

@freezed
class CommandPaletteState with _$CommandPaletteState {
  const CommandPaletteState._();

  const factory CommandPaletteState({
    @Default(null) String? query,
    required List<SearchResultPB> results,
    required bool isLoading,
    @Default([]) List<TrashPB> trash,
  }) = _CommandPaletteState;

  factory CommandPaletteState.initial() =>
      const CommandPaletteState(results: [], isLoading: false);
}

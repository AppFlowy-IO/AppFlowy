import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:appflowy/plugins/trash/application/trash_listener.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/command_palette/search_listener.dart';
import 'package:appflowy/workspace/application/command_palette/search_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'command_palette_bloc.freezed.dart';

const _searchChannel = 'CommandPalette';

class CommandPaletteBloc
    extends Bloc<CommandPaletteEvent, CommandPaletteState> {
  CommandPaletteBloc() : super(CommandPaletteState.initial()) {
    _searchListener.start(
      onResultsChanged: _onResultsChanged,
    );

    _initTrash();
    _dispatch();
  }

  Timer? _debounceOnChanged;
  final TrashService _trashService = TrashService();
  final SearchListener _searchListener = SearchListener(
    channel: _searchChannel,
  );
  final TrashListener _trashListener = TrashListener();
  String? _oldQuery;
  String? _workspaceId;
  int _messagesReceived = 0;

  @override
  Future<void> close() {
    _trashListener.close();
    _searchListener.stop();
    _debounceOnChanged?.cancel();
    return super.close();
  }

  void _dispatch() {
    on<CommandPaletteEvent>((event, emit) async {
      event.when(
        searchChanged: _debounceOnSearchChanged,
        trashChanged: (trash) async {
          if (trash != null) {
            return emit(state.copyWith(trash: trash));
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
          if (search.isNotEmpty && search != state.query) {
            _oldQuery = state.query;
            emit(state.copyWith(query: search, isLoading: true));
            await SearchBackendService.performSearch(
              search,
              workspaceId: _workspaceId,
              channel: _searchChannel,
            );
          } else {
            emit(state.copyWith(query: null, isLoading: false, results: []));
          }
        },
        resultsChanged: (results) {
          if (state.query != _oldQuery) {
            emit(state.copyWith(results: [], isLoading: true));
            _oldQuery = state.query;
            _messagesReceived = 0;
          }

          if (state.query != results.query) {
            return;
          }

          _messagesReceived++;

          final allItems = [...state.results, ...results.items];
          final searchResults = _removeDuplicates(allItems);
          searchResults.sort((a, b) => b.score.compareTo(a.score));

          emit(
            state.copyWith(
              results: searchResults,
              isLoading: _messagesReceived != results.sends.toInt(),
            ),
          );
        },
        workspaceChanged: (workspaceId) {
          _workspaceId = workspaceId;
          emit(state.copyWith(results: [], query: '', isLoading: false));
        },
        clearSearch: () {
          emit(state.copyWith(results: [], query: '', isLoading: false));
        },
      );
    });
  }

  Future<void> _initTrash() async {
    _trashListener.start(
      trashUpdated: (trashOrFailed) {
        final trash = trashOrFailed.toNullable();
        add(CommandPaletteEvent.trashChanged(trash: trash));
      },
    );

    final trashOrFailure = await _trashService.readTrash();
    final trash = trashOrFailure.toNullable();

    add(CommandPaletteEvent.trashChanged(trash: trash?.items));
  }

  void _debounceOnSearchChanged(String value) {
    _debounceOnChanged?.cancel();
    _debounceOnChanged = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(value),
    );
  }

  /// Remove duplicates, where retained item is the one with the highest score.
  List<SearchResultPB> _removeDuplicates(List<SearchResultPB> items) {
    final res = <SearchResultPB>[];

    for (final item in items) {
      final duplicateIndex = res.indexWhere((a) => a.id == item.id);
      if (duplicateIndex == -1) {
        res.add(item);
        continue;
      }

      var (keep, discard) = item.score > res[duplicateIndex].score
          ? (item, res[duplicateIndex])
          : (res[duplicateIndex], item);

      if (keep.preview.isEmpty && discard.preview.isNotEmpty) {
        keep.freeze();
        keep = keep.rebuild((i) => i.preview = discard.preview);
      }

      res[duplicateIndex] = keep;
    }

    return res;
  }

  void _performSearch(String value) =>
      add(CommandPaletteEvent.performSearch(search: value));

  void _onResultsChanged(SearchResultNotificationPB results) =>
      add(CommandPaletteEvent.resultsChanged(results: results));
}

@freezed
class CommandPaletteEvent with _$CommandPaletteEvent {
  const factory CommandPaletteEvent.searchChanged({required String search}) =
      _SearchChanged;

  const factory CommandPaletteEvent.performSearch({required String search}) =
      _PerformSearch;

  const factory CommandPaletteEvent.resultsChanged({
    required SearchResultNotificationPB results,
  }) = _ResultsChanged;

  const factory CommandPaletteEvent.trashChanged({
    @Default(null) List<TrashPB>? trash,
  }) = _TrashChanged;

  const factory CommandPaletteEvent.workspaceChanged({
    @Default(null) String? workspaceId,
  }) = _WorkspaceChanged;

  const factory CommandPaletteEvent.clearSearch() = _ClearSearch;
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

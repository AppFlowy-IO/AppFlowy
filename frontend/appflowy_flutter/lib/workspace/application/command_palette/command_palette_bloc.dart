import 'dart:async';

import 'package:appflowy/plugins/trash/application/trash_listener.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/command_palette/search_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_palette_bloc.freezed.dart';

class CommandPaletteBloc
    extends Bloc<CommandPaletteEvent, CommandPaletteState> {
  CommandPaletteBloc() : super(CommandPaletteState.initial()) {
    // Register event handlers
    on<_SearchChanged>(_onSearchChanged);
    on<_PerformSearch>(_onPerformSearch);
    on<_NewSearchStream>(_onNewSearchStream);
    on<_ResultsChanged>(_onResultsChanged);
    on<_TrashChanged>(_onTrashChanged);
    on<_WorkspaceChanged>(_onWorkspaceChanged);
    on<_ClearSearch>(_onClearSearch);

    _initTrash();
  }

  Timer? _debounceOnChanged;
  final TrashService _trashService = TrashService();
  final TrashListener _trashListener = TrashListener();
  String? _oldQuery;
  String? _workspaceId;

  @override
  Future<void> close() {
    _trashListener.close();
    _debounceOnChanged?.cancel();
    state.searchResponseStream?.dispose();
    return super.close();
  }

  Future<void> _initTrash() async {
    // Start listening for trash updates
    _trashListener.start(
      trashUpdated: (trashOrFailed) {
        add(
          CommandPaletteEvent.trashChanged(
            trash: trashOrFailed.toNullable(),
          ),
        );
      },
    );

    // Read initial trash state and forward results
    final trashOrFailure = await _trashService.readTrash();
    add(
      CommandPaletteEvent.trashChanged(
        trash: trashOrFailure.toNullable()?.items,
      ),
    );
  }

  FutureOr<void> _onSearchChanged(
    _SearchChanged event,
    Emitter<CommandPaletteState> emit,
  ) {
    _debounceOnChanged?.cancel();
    _debounceOnChanged = Timer(
      const Duration(milliseconds: 300),
      () {
        if (!isClosed) {
          add(CommandPaletteEvent.performSearch(search: event.search));
        }
      },
    );
  }

  FutureOr<void> _onPerformSearch(
    _PerformSearch event,
    Emitter<CommandPaletteState> emit,
  ) async {
    if (event.search.isNotEmpty && event.search != state.query) {
      _oldQuery = state.query;
      emit(state.copyWith(query: event.search, isLoading: true));

      // Fire off search asynchronously (fire and forget)
      unawaited(
        SearchBackendService.performSearch(
          event.search,
          workspaceId: _workspaceId,
        ).then(
          (result) => result.onSuccess((stream) {
            if (!isClosed) {
              add(CommandPaletteEvent.newSearchStream(stream: stream));
            }
          }),
        ),
      );
    } else {
      // Clear state if search is empty or unchanged
      emit(
        state.copyWith(
          query: null,
          isLoading: false,
          resultItems: [],
          resultSummaries: [],
        ),
      );
    }
  }

  FutureOr<void> _onNewSearchStream(
    _NewSearchStream event,
    Emitter<CommandPaletteState> emit,
  ) {
    state.searchResponseStream?.dispose();
    emit(
      state.copyWith(
        searchId: event.stream.searchId,
        searchResponseStream: event.stream,
      ),
    );

    event.stream.listen(
      onItems: (
        List<SearchResponseItemPB> items,
        String searchId,
        bool isLoading,
      ) {
        if (_isActiveSearch(searchId)) {
          add(
            CommandPaletteEvent.resultsChanged(
              items: items,
              searchId: searchId,
              isLoading: isLoading,
            ),
          );
        }
      },
      onSummaries: (
        List<SearchSummaryPB> summaries,
        String searchId,
        bool isLoading,
      ) {
        if (_isActiveSearch(searchId)) {
          add(
            CommandPaletteEvent.resultsChanged(
              summaries: summaries,
              searchId: searchId,
              isLoading: isLoading,
            ),
          );
        }
      },
      onFinished: (String searchId) {
        if (_isActiveSearch(searchId)) {
          add(
            CommandPaletteEvent.resultsChanged(
              searchId: searchId,
              isLoading: false,
            ),
          );
        }
      },
    );
  }

  FutureOr<void> _onResultsChanged(
    _ResultsChanged event,
    Emitter<CommandPaletteState> emit,
  ) async {
    // If query was updated since last emission, clear previous results.
    if (state.query != _oldQuery) {
      emit(
        state.copyWith(
          resultItems: [],
          resultSummaries: [],
          isLoading: event.isLoading,
        ),
      );
      _oldQuery = state.query;
    }

    // Check for outdated search streams
    if (state.searchId != event.searchId) return;

    final updatedItems =
        event.items ?? List<SearchResponseItemPB>.from(state.resultItems);
    final updatedSummaries =
        event.summaries ?? List<SearchSummaryPB>.from(state.resultSummaries);

    emit(
      state.copyWith(
        resultItems: updatedItems,
        resultSummaries: updatedSummaries,
        isLoading: event.isLoading,
      ),
    );
  }

  // Update trash state and, in case of null, retry reading trash from the service
  FutureOr<void> _onTrashChanged(
    _TrashChanged event,
    Emitter<CommandPaletteState> emit,
  ) async {
    if (event.trash != null) {
      emit(state.copyWith(trash: event.trash!));
    } else {
      final trashOrFailure = await _trashService.readTrash();
      trashOrFailure.fold((trash) {
        emit(state.copyWith(trash: trash.items));
      }, (error) {
        // Optionally handle error; otherwise, we simply do nothing.
      });
    }
  }

  // Update the workspace and clear current search results and query
  FutureOr<void> _onWorkspaceChanged(
    _WorkspaceChanged event,
    Emitter<CommandPaletteState> emit,
  ) {
    _workspaceId = event.workspaceId;
    emit(
      state.copyWith(
        query: '',
        resultItems: [],
        resultSummaries: [],
        isLoading: false,
      ),
    );
  }

  // Clear search state
  FutureOr<void> _onClearSearch(
    _ClearSearch event,
    Emitter<CommandPaletteState> emit,
  ) {
    emit(
      state.copyWith(
        query: '',
        resultItems: [],
        resultSummaries: [],
        isLoading: false,
        searchId: null,
      ),
    );
  }

  bool _isActiveSearch(String searchId) =>
      !isClosed && state.searchId == searchId;
}

@freezed
class CommandPaletteEvent with _$CommandPaletteEvent {
  const factory CommandPaletteEvent.searchChanged({required String search}) =
      _SearchChanged;
  const factory CommandPaletteEvent.performSearch({required String search}) =
      _PerformSearch;
  const factory CommandPaletteEvent.newSearchStream({
    required SearchResponseStream stream,
  }) = _NewSearchStream;
  const factory CommandPaletteEvent.resultsChanged({
    required String searchId,
    required bool isLoading,
    List<SearchResponseItemPB>? items,
    List<SearchSummaryPB>? summaries,
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
    @Default([]) List<SearchResponseItemPB> resultItems,
    @Default([]) List<SearchSummaryPB> resultSummaries,
    @Default(null) SearchResponseStream? searchResponseStream,
    required bool isLoading,
    @Default([]) List<TrashPB> trash,
    @Default(null) String? searchId,
  }) = _CommandPaletteState;

  factory CommandPaletteState.initial() =>
      const CommandPaletteState(isLoading: false);
}

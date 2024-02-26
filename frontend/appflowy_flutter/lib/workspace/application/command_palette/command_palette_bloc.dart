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
            await SearchBackendService.performSearch(search);
          }
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

  void _performSearch(String value) =>
      add(CommandPaletteEvent.performSearch(search: value));

  void _onResultsChanged(RepeatedSearchResultPB results) {}

  void _onResultsClosed(RepeatedSearchResultPB results) {}
}

@freezed
class CommandPaletteEvent with _$CommandPaletteEvent {
  const factory CommandPaletteEvent.searchChanged({required String search}) =
      _SearchChanged;

  const factory CommandPaletteEvent.performSearch({required String search}) =
      _PerformSearch;
}

@freezed
class CommandPaletteState with _$CommandPaletteState {
  const CommandPaletteState._();

  const factory CommandPaletteState({
    required List<SearchResultPB> results,
    required bool isLoading,
  }) = _CommandPaletteState;

  factory CommandPaletteState.initial() =>
      const CommandPaletteState(results: [], isLoading: false);
}

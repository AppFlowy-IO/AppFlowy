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
  Timer? _debounceOnChanged;
  final SearchListener _searchListener = SearchListener();

  CommandPaletteBloc() : super(const _Initial()) {
    on<CommandPaletteEvent>((event, emit) async {
      _searchListener.start(
        onResultsChanged: _onResultsChanged,
        onResultsClosed: _onResultsClosed,
      );

      event.when(
        searchChanged: _debounceOnSearchChanged,
        performSearch: (search) async {
          if (search.isEmpty) {
            return;
          }

          final searchOrFailure =
              await SearchBackendService.performSearch(search);

          searchOrFailure.fold(
            (results) {
              // TODO: Emit results to Presentation layer
            },
            (r) {
              // TODO: Emit no-results to Presentation layer
            },
          );
        },
      );
    });
  }

  @override
  Future<void> close() {
    _searchListener.stop();
    return super.close();
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

  void _onResultsChanged(RepeatedSearchResultPB results) {
    debugPrint("REACHED OPEN");
    for (final item in results.items) {
      debugPrint("ITEM: ${item.data}");
    }
  }

  void _onResultsClosed(RepeatedSearchResultPB results) {
    debugPrint("REACHED CLOSED");
    for (final item in results.items) {
      debugPrint("ITEM: ${item.data}");
    }
  }
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
  const factory CommandPaletteState.initial() = _Initial;
}

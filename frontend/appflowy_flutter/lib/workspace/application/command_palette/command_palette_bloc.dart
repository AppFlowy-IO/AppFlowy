import 'dart:async';

import 'package:appflowy/workspace/application/command_palette/search_service.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_palette_bloc.freezed.dart';

class CommandPaletteBloc
    extends Bloc<CommandPaletteEvent, CommandPaletteState> {
  Timer? _debounceOnChanged;

  CommandPaletteBloc() : super(const _Initial()) {
    on<CommandPaletteEvent>((event, emit) async {
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

  void _debounceOnSearchChanged(String value) {
    _debounceOnChanged?.cancel();
    _debounceOnChanged = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(value),
    );
  }

  void _performSearch(String value) =>
      add(CommandPaletteEvent.performSearch(search: value));
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

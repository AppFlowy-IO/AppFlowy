import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ShortcutsStatus { initial, updating, success, failure }

class ShortcutsCubit extends Cubit<ShortcutsState> {
  ShortcutsCubit(this.service) : super(const ShortcutsState());

  final SettingsShortcutService service;

  Future<void> fetchShortcuts() async {
    emit(state.copyWith(status: ShortcutsStatus.updating));
    try {
      final newCommandShortcuts = await service.loadShortcuts();
      emit(
        state.copyWith(
          status: ShortcutsStatus.success,
          commandShortcutEvents: newCommandShortcuts,
        ),
      );
    } catch (e) {
      //could also show an error
      debugPrint("could not load ${e.toString()}");
      emit(state.copyWith(status: ShortcutsStatus.failure));
    }
  }

  Future<void> updateAllShortcuts() async {
    emit(state.copyWith(status: ShortcutsStatus.updating));

    try {
      service.saveAllShortcuts(state.commandShortcutEvents);
      emit(state.copyWith(status: ShortcutsStatus.success));
    } catch (_) {
      emit(state.copyWith(status: ShortcutsStatus.failure));
    }
  }

  String getConflict(String command) {
    final conflict = state.commandShortcutEvents
        .firstWhereOrNull((el) => el.command == command);
    return conflict != null ? conflict.key : '';
  }
}

class ShortcutsState extends Equatable {
  final List<CommandShortcutEvent> commandShortcutEvents;
  final ShortcutsStatus status;

  const ShortcutsState({
    this.commandShortcutEvents = const <CommandShortcutEvent>[],
    this.status = ShortcutsStatus.initial,
  });

  ShortcutsState copyWith({
    ShortcutsStatus? status,
    List<CommandShortcutEvent>? commandShortcutEvents,
  }) {
    return ShortcutsState(
      status: status ?? this.status,
      commandShortcutEvents:
          commandShortcutEvents ?? this.commandShortcutEvents,
    );
  }

  @override
  List<Object?> get props => [status];
}

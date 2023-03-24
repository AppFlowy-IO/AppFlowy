import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
      List<ShortcutEvent> newShortcuts = await service.loadShortcuts();
      emit(state.copyWith(
          status: ShortcutsStatus.success, shortcuts: newShortcuts));
    } catch (e) {
      //could also show an error
      debugPrint("could not load ${e.toString()}");
      emit(state.copyWith(status: ShortcutsStatus.failure));
    }
  }

  Future<void> updateShortcuts() async {
    emit(state.copyWith(status: ShortcutsStatus.updating));

    try {
      service.saveShortcuts(state.shortcuts);
      emit(state.copyWith(status: ShortcutsStatus.success));
    } catch (_) {
      emit(state.copyWith(status: ShortcutsStatus.failure));
    }
  }
}

class ShortcutsState extends Equatable {
  final List<ShortcutEvent> shortcuts;
  final ShortcutsStatus status;

  const ShortcutsState({
    this.shortcuts = const <ShortcutEvent>[],
    this.status = ShortcutsStatus.initial,
  });

  ShortcutsState copyWith({
    ShortcutsStatus? status,
    List<ShortcutEvent>? shortcuts,
  }) {
    return ShortcutsState(
      status: status ?? this.status,
      shortcuts: shortcuts ?? this.shortcuts,
    );
  }

  @override
  List<Object?> get props => [status];
}

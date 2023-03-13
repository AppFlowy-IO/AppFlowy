import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShortcutsCubit extends Cubit<ShortcutsState> {
  ShortcutsCubit() : super(const ShortcutsState());

  void fetchShortcuts() {
    emit(state.copyWith(
        status: ShortcutsStatus.success, shortcuts: builtInShortcutEvents));
  }

  void updateShortcut(
      {required ShortcutEvent shortcutEvent, required String command}) {
    emit(state.copyWith(status: ShortcutsStatus.updating));
    shortcutEvent.updateCommand(command: command);
    emit(state.copyWith(
        status: ShortcutsStatus.success, shortcuts: builtInShortcutEvents));
  }
}

enum ShortcutsStatus { initial, updating, success, failure }

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

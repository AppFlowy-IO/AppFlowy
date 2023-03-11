import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShortcutsCubit extends Cubit<ShortcutsState> {
  ShortcutsCubit() : super(const ShortcutsState());

  void fetchShortcuts() {
    print("Inside Fetch Shortcuts");
    emit(state.copyWith(
        status: ShortcutsStatus.success, shortcuts: builtInShortcutEvents));
  }
}

enum ShortcutsStatus { initial, success, failure }

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

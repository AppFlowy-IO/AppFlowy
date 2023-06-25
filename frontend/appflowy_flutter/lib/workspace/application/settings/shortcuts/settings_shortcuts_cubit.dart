import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_shortcuts_cubit.freezed.dart';

String kCouldNotLoadErrorMsg = "Could not load shortcuts,Try again";
String kCouldNotSaveErrorMsg = "Could not save shortcut, Try again";

@freezed
class ShortcutsState with _$ShortcutsState {
  const factory ShortcutsState({
    @Default(<CommandShortcutEvent>[])
    List<CommandShortcutEvent> commandShortcutEvents,
    @Default(ShortcutsStatus.initial) ShortcutsStatus status,
    @Default('') String error,
  }) = _ShortcutsState;
}

enum ShortcutsStatus { initial, updating, success, failure }

class ShortcutsCubit extends Cubit<ShortcutsState> {
  ShortcutsCubit(this.service) : super(const ShortcutsState());

  final SettingsShortcutService service;

  Future<void> fetchShortcuts() async {
    emit(
      state.copyWith(
        status: ShortcutsStatus.updating,
        error: '',
      ),
    );
    try {
      final customizeShortcuts = await service.getCustomizeShortcuts();
      await service.updateCommandShortcuts(
        commandShortcutEvents,
        customizeShortcuts,
      );
      emit(
        state.copyWith(
          status: ShortcutsStatus.success,
          commandShortcutEvents: commandShortcutEvents,
          error: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ShortcutsStatus.failure,
          error: kCouldNotLoadErrorMsg,
        ),
      );
    }
  }

  Future<void> updateAllShortcuts() async {
    emit(
      state.copyWith(
        status: ShortcutsStatus.updating,
        error: '',
      ),
    );
    try {
      await service.saveAllShortcuts(state.commandShortcutEvents);
      emit(
        state.copyWith(
          status: ShortcutsStatus.success,
          error: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ShortcutsStatus.failure,
          error: kCouldNotSaveErrorMsg,
        ),
      );
    }
  }

  Future<void> resetToDefault() async {
    emit(
      state.copyWith(
        status: ShortcutsStatus.updating,
        error: '',
      ),
    );
    try {
      await service.saveAllShortcuts(defaultCommandShortcutEvents);
      emit(
        state.copyWith(
          status: ShortcutsStatus.success,
          commandShortcutEvents: defaultCommandShortcutEvents,
          error: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ShortcutsStatus.failure,
          error: kCouldNotSaveErrorMsg,
        ),
      );
    }
  }

  String getConflict(String command) {
    final conflict = state.commandShortcutEvents
        .firstWhereOrNull((el) => el.command == command);
    return conflict?.key ?? '';
  }
}

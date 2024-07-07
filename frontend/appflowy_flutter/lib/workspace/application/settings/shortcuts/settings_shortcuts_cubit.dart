import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_shortcuts_cubit.freezed.dart';

@freezed
class ShortcutsState with _$ShortcutsState {
  const factory ShortcutsState({
    @Default(<CommandShortcutEvent>[])
    List<CommandShortcutEvent> commandShortcutEvents,
    @Default(ShortcutsStatus.initial) ShortcutsStatus status,
    @Default('') String error,
  }) = _ShortcutsState;
}

enum ShortcutsStatus {
  initial,
  updating,
  success,
  failure;

  /// Helper getter for when the [ShortcutsStatus] signifies
  /// that the shortcuts have not been loaded yet.
  ///
  bool get isLoading => [initial, updating].contains(this);

  /// Helper getter for when the [ShortcutsStatus] signifies
  /// a failure by itself being [ShortcutsStatus.failure]
  ///
  bool get isFailure => this == ShortcutsStatus.failure;

  /// Helper getter for when the [ShortcutsStatus] signifies
  /// a success by itself being [ShortcutsStatus.success]
  ///
  bool get isSuccess => this == ShortcutsStatus.success;
}

class ShortcutsCubit extends Cubit<ShortcutsState> {
  ShortcutsCubit(this.service) : super(const ShortcutsState());

  final SettingsShortcutService service;

  /// Fetches and updates shortcut data.
  ///
  /// This method retrieves customizable shortcuts data from ShortcutService instance
  /// and updates the command shortcuts based on the provided data and current state.
  ///
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

      //sort the shortcuts
      commandShortcutEvents.sort(
        (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
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
          error: LocaleKeys.settings_shortcutsPage_couldNotLoadErrorMsg.tr(),
        ),
      );
    }
  }

  /// Saves all updated shortcuts to the Shortcut Service instance we are using.
  Future<void> updateAllShortcuts() async {
    emit(state.copyWith(status: ShortcutsStatus.updating, error: ''));

    try {
      await service.saveAllShortcuts(state.commandShortcutEvents);
      emit(state.copyWith(status: ShortcutsStatus.success, error: ''));
    } catch (e) {
      emit(
        state.copyWith(
          status: ShortcutsStatus.failure,
          error: LocaleKeys.settings_shortcutsPage_couldNotSaveErrorMsg.tr(),
        ),
      );
    }
  }

  /// This method resets all shortcuts to their default commands.
  Future<void> resetToDefault() async {
    emit(state.copyWith(status: ShortcutsStatus.updating, error: ''));

    try {
      await service.saveAllShortcuts(defaultCommandShortcutEvents);
      await fetchShortcuts();
    } catch (e) {
      emit(
        state.copyWith(
          status: ShortcutsStatus.failure,
          error: LocaleKeys.settings_shortcutsPage_couldNotSaveErrorMsg.tr(),
        ),
      );
    }
  }

  /// Resets an individual shortcut to its default shortcut command.
  /// Takes in the shortcut to reset.
  Future<void> resetIndividualShortcut(CommandShortcutEvent shortcut) async {
    emit(state.copyWith(status: ShortcutsStatus.updating, error: ''));

    try {
      // If no shortcut is found in the `defaultCommandShortcutEvents` then
      // it will throw an error which will be handled by our catch block.
      final defaultShortcut = defaultCommandShortcutEvents.firstWhere(
        (el) => el.key == shortcut.key && el.handler == shortcut.handler,
      );

      // only update the shortcut if it is overidden
      if (defaultShortcut.command != shortcut.command) {
        shortcut.updateCommand(command: defaultShortcut.command);
        await service.saveAllShortcuts(state.commandShortcutEvents);
      }

      emit(state.copyWith(status: ShortcutsStatus.success, error: ''));
    } catch (e) {
      emit(
        state.copyWith(
          status: ShortcutsStatus.failure,
          // TODO: replace this string with the correct localized string.
          error: LocaleKeys.settings_shortcutsPage_couldNotSaveErrorMsg.tr(),
        ),
      );
    }
  }

  /// Checks if the new command is conflicting with other shortcut
  /// We also check using the key, whether this command is a codeblock
  /// shortcut, if so we only check a conflict with other codeblock shortcut.
  CommandShortcutEvent? getConflict(
    CommandShortcutEvent currentShortcut,
    String command,
  ) {
    // check if currentShortcut is a codeblock shortcut.
    final isCodeBlockCommand = currentShortcut.isCodeBlockCommand;

    for (final e in state.commandShortcutEvents) {
      if (e.command == command && e.isCodeBlockCommand == isCodeBlockCommand) {
        return e;
      }
    }

    return null;
  }
}

extension on CommandShortcutEvent {
  bool get isCodeBlockCommand => localizedCodeBlockCommands.contains(this);
}

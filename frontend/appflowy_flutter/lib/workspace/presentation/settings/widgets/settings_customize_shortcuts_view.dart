import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_cubit.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsShortcutsView extends StatelessWidget {
  const SettingsShortcutsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShortcutsCubit>(
      create: (_) =>
          ShortcutsCubit(SettingsShortcutService())..fetchShortcuts(),
      child: SettingsBody(
        children: [
          SettingsHeader(
            title: LocaleKeys.settings_shortcuts_shortcutsLabel.tr(),
          ),
          BlocBuilder<ShortcutsCubit, ShortcutsState>(
            builder: (_, state) => switch (state.status) {
              ShortcutsStatus.initial ||
              ShortcutsStatus.updating =>
                const Center(child: CircularProgressIndicator()),
              ShortcutsStatus.success =>
                ShortcutsListView(shortcuts: state.commandShortcutEvents),
              ShortcutsStatus.failure =>
                ShortcutsErrorView(errorMessage: state.error),
            },
          ),
        ],
      ),
    );
  }
}

class ShortcutsListView extends StatelessWidget {
  const ShortcutsListView({super.key, required this.shortcuts});

  final List<CommandShortcutEvent> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FlowyText.semibold(
                LocaleKeys.settings_shortcuts_command.tr(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FlowyText.semibold(
              LocaleKeys.settings_shortcuts_keyBinding.tr(),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const VSpace(10),
        ...shortcuts.map((e) => ShortcutsListTile(shortcutEvent: e)),
        const VSpace(10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Spacer(),
            FlowyTextButton(
              LocaleKeys.settings_shortcuts_resetToDefault.tr(),
              fontColor: AFThemeExtension.of(context).textColor,
              onPressed: () => context.read<ShortcutsCubit>().resetToDefault(),
            ),
          ],
        ),
        const VSpace(10),
      ],
    );
  }
}

class ShortcutsListTile extends StatelessWidget {
  const ShortcutsListTile({
    super.key,
    required this.shortcutEvent,
  });

  final CommandShortcutEvent shortcutEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FlowyText.medium(
                key: Key(shortcutEvent.key),
                shortcutEvent.description!.capitalize(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FlowyTextButton(
              shortcutEvent.command,
              fillColor: Colors.transparent,
              fontColor: AFThemeExtension.of(context).textColor,
              onPressed: () => showKeyListenerDialog(context),
            ),
          ],
        ),
        Divider(
          color: Theme.of(context).dividerColor,
        ),
      ],
    );
  }

  void showKeyListenerDialog(BuildContext widgetContext) {
    final controller = TextEditingController(text: shortcutEvent.command);
    showDialog(
      context: widgetContext,
      builder: (builderContext) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: Text(LocaleKeys.settings_shortcuts_updateShortcutStep.tr()),
          content: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (key) {
              if (key.logicalKey == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                if (controller.text == shortcutEvent.command) {
                  _dismiss(builderContext);
                }
                if (formKey.currentState!.validate()) {
                  _updateKey(widgetContext, controller.text);
                  _dismiss(builderContext);
                }
              } else if (key.logicalKey == LogicalKeyboardKey.escape) {
                _dismiss(builderContext);
              } else {
                //extract the keybinding command from the key event.
                controller.text = key.convertToCommand;
              }
            },
            child: Form(
              key: formKey,
              child: TextFormField(
                autofocus: true,
                controller: controller,
                readOnly: true,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                validator: (_) => _validateForConflicts(
                  widgetContext,
                  controller.text,
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) => controller.dispose());
  }

  String? _validateForConflicts(BuildContext context, String command) {
    final conflict = BlocProvider.of<ShortcutsCubit>(context).getConflict(
      shortcutEvent,
      command,
    );
    if (conflict.isEmpty) return null;

    return LocaleKeys.settings_shortcuts_shortcutIsAlreadyUsed.tr(
      namedArgs: {'conflict': conflict},
    );
  }

  void _updateKey(BuildContext context, String command) {
    shortcutEvent.updateCommand(command: command);
    BlocProvider.of<ShortcutsCubit>(context).updateAllShortcuts();
  }

  void _dismiss(BuildContext context) => Navigator.of(context).pop();
}

extension on KeyEvent {
  String get convertToCommand {
    String command = '';
    if (HardwareKeyboard.instance.isAltPressed) {
      command += 'alt+';
    }
    if (HardwareKeyboard.instance.isControlPressed) {
      command += 'ctrl+';
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      command += 'shift+';
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      command += 'meta+';
    }

    final keyPressed = keyToCodeMapping.keys.firstWhere(
      (k) => keyToCodeMapping[k] == logicalKey.keyId,
      orElse: () => '',
    );

    return command += keyPressed;
  }
}

class ShortcutsErrorView extends StatelessWidget {
  const ShortcutsErrorView({super.key, required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            errorMessage,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        FlowyIconButton(
          icon: const Icon(Icons.replay_outlined),
          onPressed: () => context.read<ShortcutsCubit>().fetchShortcuts(),
        ),
      ],
    );
  }
}

import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcut_cubit.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCustomizeShortcuts extends StatelessWidget {
  const SettingsCustomizeShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShortcutsCubit>(
      create: (_) =>
          ShortcutsCubit(SettingsShortcutService())..fetchShortcuts(),
      child: const CustomizeShortcutsView(),
    );
  }
}

class CustomizeShortcutsView extends StatelessWidget {
  const CustomizeShortcutsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShortcutsCubit, ShortcutsState>(
      builder: (context, state) {
        switch (state.status) {
          case ShortcutsStatus.success:
            return ShortcutsListView(shortcuts: state.shortcuts);
          case ShortcutsStatus.failure:
            return const ShortcutsErrorView();
          case ShortcutsStatus.initial:
          case ShortcutsStatus.updating:
            return const Center(
              child: CircularProgressIndicator(),
            );
        }
      },
    );
  }
}

class ShortcutsListView extends StatelessWidget {
  final List<ShortcutEvent> shortcuts;
  const ShortcutsListView({super.key, required this.shortcuts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              child: FlowyText.semibold(
                "Command",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FlowyText.semibold(
              "Key Binding ",
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: shortcuts.length,
            itemBuilder: ((context, i) {
              return ShortcutsListTile(shortcutEvent: shortcuts[i]);
            }),
          ),
        )
      ],
    );
  }
}

class ShortcutsListTile extends StatelessWidget {
  final ShortcutEvent shortcutEvent;
  const ShortcutsListTile({
    super.key,
    required this.shortcutEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            shortcutEvent.key,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        FlowyTextButton(
          shortcutEvent.command,
          fillColor: Colors.transparent,
          onPressed: () {
            showKeyListenerDialog(context);
          },
        )
      ],
    );
  }

  void showKeyListenerDialog(BuildContext widgetContext) {
    showDialog(
      context: widgetContext,
      builder: (builderContext) {
        final controller = TextEditingController(text: shortcutEvent.command);
        return AlertDialog(
          title: const Text('Press desired key combination and press Enter'),
          content: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (key) {
              if (key is! RawKeyDownEvent) return;
              if (key.logicalKey == LogicalKeyboardKey.enter &&
                  !key.isShiftPressed) {
                _updateKey(widgetContext, controller.text);
                _dismiss(builderContext);
              } else if (key.logicalKey == LogicalKeyboardKey.escape) {
                _dismiss(builderContext);
              } else {
                //extract the keybinding command from the rawkeyevent.
                controller.text = key.convertToCommand;
              }
            },
            child: TextField(
              autofocus: true,
              controller: controller,
              readOnly: true,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
        );
      },
    );
  }

  _updateKey(BuildContext context, String command) {
    shortcutEvent.updateCommand(command: command);
    BlocProvider.of<ShortcutsCubit>(context).updateShortcuts();
  }

  _dismiss(BuildContext context) => Navigator.of(context).pop();
}

extension on RawKeyEvent {
  String get convertToCommand {
    String command = '';
    if (isAltPressed) {
      command += 'alt+';
    }
    if (isControlPressed) {
      command += 'ctrl+';
    }
    if (isShiftPressed) {
      command += 'shift+';
    }
    if (isMetaPressed) {
      command += 'meta+';
    }
    String keyPressed = keyToCodeMapping.keys.firstWhere(
        (k) => keyToCodeMapping[k] == logicalKey.keyId,
        orElse: () => '');
    command += keyPressed;
    return command;
  }
}

class ShortcutsErrorView extends StatelessWidget {
  const ShortcutsErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: FlowyText.medium(
            "Could Not Load Shortcuts",
            overflow: TextOverflow.ellipsis,
          ),
        ),
        FlowyIconButton(
          icon: const Icon(Icons.replay_outlined),
          onPressed: () {
            BlocProvider.of<ShortcutsCubit>(context).fetchShortcuts();
          },
        ),
      ],
    );
  }
}

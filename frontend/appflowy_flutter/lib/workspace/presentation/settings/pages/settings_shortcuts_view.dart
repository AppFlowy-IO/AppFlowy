import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/align_toolbar_item/custom_text_align_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/custom_copy_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/custom_cut_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/custom_paste_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toggle/toggle_block_shortcut_event.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_cubit.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_shortcut_event.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsShortcutsView extends StatefulWidget {
  const SettingsShortcutsView({super.key});

  @override
  State<SettingsShortcutsView> createState() => _SettingsShortcutsViewState();
}

class _SettingsShortcutsViewState extends State<SettingsShortcutsView> {
  String _query = '';
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ShortcutsCubit(SettingsShortcutService())..fetchShortcuts(),
      child: Builder(
        builder: (context) => SettingsBody(
          title: LocaleKeys.settings_shortcutsPage_title.tr(),
          autoSeparate: false,
          children: [
            Row(
              children: [
                Flexible(
                  child: _SearchBar(
                    onSearchChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const HSpace(10),
                _ResetButton(
                  onReset: () => SettingsAlertDialog(
                    isDangerous: true,
                    title: LocaleKeys.settings_shortcutsPage_resetDialog_title
                        .tr(),
                    subtitle: LocaleKeys
                        .settings_shortcutsPage_resetDialog_description
                        .tr(),
                    confirmLabel: LocaleKeys
                        .settings_shortcutsPage_resetDialog_buttonLabel
                        .tr(),
                    confirm: () {
                      Navigator.of(context).pop();
                      context.read<ShortcutsCubit>().resetToDefault();
                    },
                  ).show(context),
                ),
              ],
            ),
            BlocBuilder<ShortcutsCubit, ShortcutsState>(
              builder: (context, state) {
                final filtered = state.commandShortcutEvents
                    .where(
                      (e) => e.afLabel
                          .toLowerCase()
                          .contains(_query.toLowerCase()),
                    )
                    .toList();

                return Column(
                  children: [
                    const VSpace(16),
                    if (state.status.isLoading) ...[
                      const CircularProgressIndicator(),
                    ] else if (state.status.isFailure) ...[
                      FlowyErrorPage.message(
                        LocaleKeys.settings_shortcutsPage_errorPage_message
                            .tr(args: [state.error]),
                        howToFix: LocaleKeys
                            .settings_shortcutsPage_errorPage_howToFix
                            .tr(),
                      ),
                    ] else ...[
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => ShortcutSettingTile(
                          command: filtered[index],
                          canStartEditing: () => !_isEditing,
                          onStartEditing: () =>
                              setState(() => _isEditing = true),
                          onFinishEditing: () =>
                              setState(() => _isEditing = false),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.onSearchChanged});

  final void Function(String)? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FlowyTextField(
        onChanged: onSearchChanged,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: LocaleKeys.settings_shortcutsPage_searchHint.tr(),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            vertical: 9,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: Corners.s12Border,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
            borderRadius: Corners.s12Border,
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
            borderRadius: Corners.s12Border,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
            borderRadius: Corners.s12Border,
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({this.onReset});

  final void Function()? onReset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onReset,
      child: FlowyHover(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4.0,
            horizontal: 6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FlowySvg(
                FlowySvgs.restore_s,
                size: Size.square(20),
              ),
              const HSpace(6),
              SizedBox(
                height: 16,
                child: FlowyText.regular(
                  LocaleKeys.settings_shortcutsPage_actions_resetDefault.tr(),
                  color: AFThemeExtension.of(context).strongText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShortcutSettingTile extends StatefulWidget {
  const ShortcutSettingTile({
    super.key,
    required this.command,
    required this.onStartEditing,
    required this.onFinishEditing,
    required this.canStartEditing,
  });

  final CommandShortcutEvent command;
  final VoidCallback onStartEditing;
  final VoidCallback onFinishEditing;
  final bool Function() canStartEditing;

  @override
  State<ShortcutSettingTile> createState() => _ShortcutSettingTileState();
}

class _ShortcutSettingTileState extends State<ShortcutSettingTile> {
  final keybindController = TextEditingController();

  late final FocusNode focusNode;

  bool isHovering = false;
  bool isEditing = false;
  bool canClickOutside = false;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(
      onKeyEvent: (focusNode, key) {
        if (key is! KeyDownEvent && key is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }

        if (key.logicalKey == LogicalKeyboardKey.enter &&
            !HardwareKeyboard.instance.isShiftPressed) {
          if (keybindController.text == widget.command.command) {
            _finishEditing();
            return KeyEventResult.handled;
          }

          final conflict = context.read<ShortcutsCubit>().getConflict(
                widget.command,
                keybindController.text,
              );

          if (conflict != null) {
            canClickOutside = true;
            SettingsAlertDialog(
              title: LocaleKeys.settings_shortcutsPage_conflictDialog_title
                  .tr(args: [keybindController.text]),
              confirm: () {
                conflict.clearCommand();
                _updateCommand();
                Navigator.of(context).pop();
              },
              confirmLabel: LocaleKeys
                  .settings_shortcutsPage_conflictDialog_confirmLabel
                  .tr(),
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                    children: [
                      TextSpan(
                        text: LocaleKeys
                            .settings_shortcutsPage_conflictDialog_descriptionPrefix
                            .tr(),
                      ),
                      TextSpan(
                        text: conflict.afLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextSpan(
                        text: LocaleKeys
                            .settings_shortcutsPage_conflictDialog_descriptionSuffix
                            .tr(args: [keybindController.text]),
                      ),
                    ],
                  ),
                ),
              ],
            ).show(context).then((_) => canClickOutside = false);
          } else {
            _updateCommand();
          }
        } else if (key.logicalKey == LogicalKeyboardKey.escape) {
          _finishEditing();
        } else {
          // Extract complete keybinding
          setState(() => keybindController.text = key.toCommand);
        }

        return KeyEventResult.handled;
      },
    );
  }

  void _finishEditing() => setState(() {
        isEditing = false;
        keybindController.clear();
        widget.onFinishEditing();
      });

  void _updateCommand() {
    widget.command.updateCommand(command: keybindController.text);
    context.read<ShortcutsCubit>().updateAllShortcuts();
    _finishEditing();
  }

  void _resetIndividualCommand(CommandShortcutEvent shortcut) {
    context.read<ShortcutsCubit>().resetIndividualShortcut(shortcut);
  }

  bool canResetCommand(CommandShortcutEvent shortcut) {
    final defaultShortcut = defaultCommandShortcutEvents.firstWhere(
      (el) => el.key == shortcut.key && el.handler == shortcut.handler,
    );

    return defaultShortcut.command != shortcut.command;
  }

  @override
  void dispose() {
    focusNode.dispose();
    keybindController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: FlowyHover(
        cursor: MouseCursor.defer,
        style: HoverStyle(
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.zero,
        ),
        resetHoverOnRebuild: false,
        builder: (context, isHovering) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const HSpace(8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FlowyText.regular(
                    widget.command.afLabel,
                    fontSize: 14,
                    lineHeight: 1,
                    maxLines: 2,
                    color: AFThemeExtension.of(context).strongText,
                  ),
                ),
              ),
              Expanded(
                child: isEditing
                    ? _renderKeybindEditor()
                    : _renderKeybindings(isHovering),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderKeybindings(bool isHovering) {
    final canReset = canResetCommand(widget.command);

    return Row(
      children: [
        if (widget.command.keybindings.isNotEmpty) ...[
          ..._toParts(widget.command.keybindings.first).map(
            (key) => KeyBadge(keyLabel: key),
          ),
        ] else ...[
          const SizedBox(height: 24),
        ],
        const Spacer(),
        if (isHovering)
          Row(
            children: [
              EditShortcutBtn(
                onEdit: () {
                  if (widget.canStartEditing()) {
                    setState(() {
                      widget.onStartEditing();
                      isEditing = true;
                    });
                  }
                },
              ),
              const HSpace(16),
              ResetShortcutBtn(
                onReset: () => _resetIndividualCommand(widget.command),
                canReset: canReset,
              ),
            ],
          ),
        const HSpace(8),
      ],
    );
  }

  Widget _renderKeybindEditor() => TapRegion(
        onTapOutside: canClickOutside ? null : (_) => _finishEditing(),
        child: FlowyTextField(
          focusNode: focusNode,
          controller: keybindController,
          hintText: LocaleKeys.settings_shortcutsPage_editBindingHint.tr(),
          onChanged: (_) => setState(() {}),
          suffixIcon: keybindController.text.isNotEmpty
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => keybindController.clear()),
                    child: const FlowySvg(
                      FlowySvgs.close_s,
                      size: Size.square(10),
                    ),
                  ),
                )
              : null,
        ),
      );

  List<String> _toParts(Keybinding binding) {
    final List<String> keys = [];

    if (binding.isControlPressed) {
      keys.add('ctrl');
    }
    if (binding.isMetaPressed) {
      keys.add('meta');
    }
    if (binding.isShiftPressed) {
      keys.add('shift');
    }
    if (binding.isAltPressed) {
      keys.add('alt');
    }

    return keys..add(binding.keyLabel);
  }
}

class EditShortcutBtn extends StatelessWidget {
  const EditShortcutBtn({super.key, required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: FlowyTooltip(
          message: LocaleKeys.settings_shortcutsPage_editTooltip.tr(),
          child: const FlowySvg(
            FlowySvgs.edit_s,
            size: Size.square(16),
          ),
        ),
      ),
    );
  }
}

class ResetShortcutBtn extends StatelessWidget {
  const ResetShortcutBtn({
    super.key,
    required this.onReset,
    required this.canReset,
  });

  final bool canReset;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: canReset ? 1 : 0.5,
      child: GestureDetector(
        onTap: canReset ? onReset : null,
        child: MouseRegion(
          cursor: canReset ? SystemMouseCursors.click : MouseCursor.defer,
          child: FlowyTooltip(
            message: canReset
                ? LocaleKeys.settings_shortcutsPage_resetSingleTooltip.tr()
                : LocaleKeys
                    .settings_shortcutsPage_unavailableResetSingleTooltip
                    .tr(),
            child: const FlowySvg(
              FlowySvgs.restore_s,
              size: Size.square(16),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class KeyBadge extends StatelessWidget {
  const KeyBadge({super.key, required this.keyLabel});

  final String keyLabel;

  @override
  Widget build(BuildContext context) {
    if (iconData == null && keyLabel.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 24,
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AFThemeExtension.of(context).greySelect,
        borderRadius: Corners.s4Border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: iconData != null
            ? FlowySvg(iconData!, color: Colors.black)
            : FlowyText.medium(
                keyLabel.toLowerCase(),
                fontSize: 12,
                color: Colors.black,
              ),
      ),
    );
  }

  FlowySvgData? get iconData => switch (keyLabel) {
        'meta' => FlowySvgs.keyboard_meta_s,
        'arrow left' => FlowySvgs.keyboard_arrow_left_s,
        'arrow right' => FlowySvgs.keyboard_arrow_right_s,
        'arrow up' => FlowySvgs.keyboard_arrow_up_s,
        'arrow down' => FlowySvgs.keyboard_arrow_down_s,
        'shift' => FlowySvgs.keyboard_shift_s,
        'tab' => FlowySvgs.keyboard_tab_s,
        'enter' || 'return' => FlowySvgs.keyboard_return_s,
        'opt' || 'option' => FlowySvgs.keyboard_option_s,
        _ => null,
      };
}

extension ToCommand on KeyEvent {
  String get toCommand {
    String command = '';
    if (HardwareKeyboard.instance.isControlPressed) {
      command += 'ctrl+';
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      command += 'meta+';
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      command += 'shift+';
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      command += 'alt+';
    }

    if ([
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ].contains(logicalKey)) {
      return command;
    }

    final keyPressed = keyToCodeMapping.keys.firstWhere(
      (k) => keyToCodeMapping[k] == logicalKey.keyId,
      orElse: () => '',
    );

    return command += keyPressed;
  }
}

extension CommandLabel on CommandShortcutEvent {
  String get afLabel {
    String? label;

    if (key == toggleToggleListCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_toggleToDoList.tr();
    } else if (key == insertNewParagraphNextToCodeBlockCommand('').key) {
      label = LocaleKeys
          .settings_shortcutsPage_keybindings_insertNewParagraphInCodeblock
          .tr();
    } else if (key == pasteInCodeblock('').key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_pasteInCodeblock.tr();
    } else if (key == selectAllInCodeBlockCommand('').key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_selectAllCodeblock.tr();
    } else if (key == tabToInsertSpacesInCodeBlockCommand('').key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_indentLineCodeblock
          .tr();
    } else if (key == tabToDeleteSpacesInCodeBlockCommand('').key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_outdentLineCodeblock
          .tr();
    } else if (key == tabSpacesAtCurosrInCodeBlockCommand('').key) {
      label = LocaleKeys
          .settings_shortcutsPage_keybindings_twoSpacesCursorCodeblock
          .tr();
    } else if (key == customCopyCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_copy.tr();
    } else if (key == customPasteCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_paste.tr();
    } else if (key == customCutCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_cut.tr();
    } else if (key == customTextLeftAlignCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_alignLeft.tr();
    } else if (key == customTextCenterAlignCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_alignCenter.tr();
    } else if (key == customTextRightAlignCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_alignRight.tr();
    } else if (key == undoCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_undo.tr();
    } else if (key == redoCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_redo.tr();
    } else if (key == convertToParagraphCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_convertToParagraph.tr();
    } else if (key == backspaceCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_backspace.tr();
    } else if (key == deleteLeftWordCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_deleteLeftWord.tr();
    } else if (key == deleteLeftSentenceCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_deleteLeftSentence.tr();
    } else if (key == deleteCommand.key) {
      label = PlatformExtension.isMacOS
          ? LocaleKeys.settings_shortcutsPage_keybindings_deleteMacOS.tr()
          : LocaleKeys.settings_shortcutsPage_keybindings_delete.tr();
    } else if (key == deleteRightWordCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_deleteRightWord.tr();
    } else if (key == moveCursorLeftCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorLeft.tr();
    } else if (key == moveCursorToBeginCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorBeginning
          .tr();
    } else if (key == moveCursorToLeftWordCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_moveCursorLeftWord.tr();
    } else if (key == moveCursorLeftSelectCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorLeftSelect
          .tr();
    } else if (key == moveCursorBeginSelectCommand.key) {
      label = LocaleKeys
          .settings_shortcutsPage_keybindings_moveCursorBeginSelect
          .tr();
    } else if (key == moveCursorLeftWordSelectCommand.key) {
      label = LocaleKeys
          .settings_shortcutsPage_keybindings_moveCursorLeftWordSelect
          .tr();
    } else if (key == moveCursorRightCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_moveCursorRight.tr();
    } else if (key == moveCursorToEndCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorEnd.tr();
    } else if (key == moveCursorToRightWordCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorRightWord
          .tr();
    } else if (key == moveCursorRightSelectCommand.key) {
      label = LocaleKeys
          .settings_shortcutsPage_keybindings_moveCursorRightSelect
          .tr();
    } else if (key == moveCursorEndSelectCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorEndSelect
          .tr();
    } else if (key == moveCursorRightWordSelectCommand.key) {
      label = LocaleKeys
          .settings_shortcutsPage_keybindings_moveCursorRightWordSelect
          .tr();
    } else if (key == moveCursorUpCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorUp.tr();
    } else if (key == moveCursorTopSelectCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorTopSelect
          .tr();
    } else if (key == moveCursorTopCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorTop.tr();
    } else if (key == moveCursorUpSelectCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_moveCursorUpSelect.tr();
    } else if (key == moveCursorDownCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorDown.tr();
    } else if (key == moveCursorBottomSelectCommand.key) {
      label = LocaleKeys
          .settings_shortcutsPage_keybindings_moveCursorBottomSelect
          .tr();
    } else if (key == moveCursorBottomCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_moveCursorBottom.tr();
    } else if (key == moveCursorDownSelectCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_moveCursorDownSelect
          .tr();
    } else if (key == homeCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_home.tr();
    } else if (key == endCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_end.tr();
    } else if (key == toggleBoldCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_toggleBold.tr();
    } else if (key == toggleItalicCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_toggleItalic.tr();
    } else if (key == toggleUnderlineCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_toggleUnderline.tr();
    } else if (key == toggleStrikethroughCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_toggleStrikethrough
          .tr();
    } else if (key == toggleCodeCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_toggleCode.tr();
    } else if (key == toggleHighlightCommand.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_toggleHighlight.tr();
    } else if (key == showLinkMenuCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_showLinkMenu.tr();
    } else if (key == openInlineLinkCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_openInlineLink.tr();
    } else if (key == openLinksCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_openLinks.tr();
    } else if (key == indentCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_indent.tr();
    } else if (key == outdentCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_outdent.tr();
    } else if (key == exitEditingCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_exit.tr();
    } else if (key == pageUpCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_pageUp.tr();
    } else if (key == pageDownCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_pageDown.tr();
    } else if (key == selectAllCommand.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_selectAll.tr();
    } else if (key == pasteTextWithoutFormattingCommand.key) {
      label = LocaleKeys
          .settings_shortcutsPage_keybindings_pasteWithoutFormatting
          .tr();
    } else if (key == emojiShortcutEvent.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_showEmojiPicker.tr();
    } else if (key == enterInTableCell.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_enterInTableCell.tr();
    } else if (key == leftInTableCell.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_leftInTableCell.tr();
    } else if (key == rightInTableCell.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_rightInTableCell.tr();
    } else if (key == upInTableCell.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_upInTableCell.tr();
    } else if (key == downInTableCell.key) {
      label =
          LocaleKeys.settings_shortcutsPage_keybindings_downInTableCell.tr();
    } else if (key == tabInTableCell.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_tabInTableCell.tr();
    } else if (key == shiftTabInTableCell.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_shiftTabInTableCell
          .tr();
    } else if (key == backSpaceInTableCell.key) {
      label = LocaleKeys.settings_shortcutsPage_keybindings_backSpaceInTableCell
          .tr();
    }

    return label ?? description?.capitalize() ?? '';
  }
}

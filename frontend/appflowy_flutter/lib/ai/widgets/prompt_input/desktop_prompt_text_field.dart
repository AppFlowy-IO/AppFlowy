import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_control_cubit.dart';
import 'package:appflowy/plugins/ai_chat/presentation/layout_define.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopPromptInput extends StatefulWidget {
  const DesktopPromptInput({
    super.key,
    required this.isStreaming,
    required this.textController,
    required this.onStopStreaming,
    required this.onSubmitted,
    required this.selectedSourcesNotifier,
    required this.onUpdateSelectedSources,
    this.hideDecoration = false,
    this.extraBottomActionButton,
  });

  final bool isStreaming;
  final TextEditingController textController;
  final void Function() onStopStreaming;
  final void Function(String, PredefinedFormat?, Map<String, dynamic>)
      onSubmitted;
  final ValueNotifier<List<String>> selectedSourcesNotifier;
  final void Function(List<String>) onUpdateSelectedSources;
  final bool hideDecoration;
  final Widget? extraBottomActionButton;

  @override
  State<DesktopPromptInput> createState() => _DesktopPromptInputState();
}

class _DesktopPromptInputState extends State<DesktopPromptInput> {
  final textFieldKey = GlobalKey();
  final layerLink = LayerLink();
  final overlayController = OverlayPortalController();
  final inputControlCubit = ChatInputControlCubit();
  final focusNode = FocusNode();

  late SendButtonState sendButtonState;
  bool isComposing = false;

  @override
  void initState() {
    super.initState();

    widget.textController.addListener(handleTextControllerChanged);
    focusNode.addListener(
      () {
        if (!widget.hideDecoration) {
          setState(() {}); // refresh border color
        }
        if (!focusNode.hasFocus) {
          cancelMentionPage(); // hide menu when lost focus
        }
      },
    );

    updateSendButtonState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    updateSendButtonState();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    focusNode.dispose();
    widget.textController.removeListener(handleTextControllerChanged);
    inputControlCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: inputControlCubit,
      child: BlocListener<ChatInputControlCubit, ChatInputControlState>(
        listener: (context, state) {
          state.maybeWhen(
            updateSelectedViews: (selectedViews) {
              context
                  .read<AIPromptInputBloc>()
                  .add(AIPromptInputEvent.updateMentionedViews(selectedViews));
            },
            orElse: () {},
          );
        },
        child: OverlayPortal(
          controller: overlayController,
          overlayChildBuilder: (context) {
            return PromptInputMentionPageMenu(
              anchor: PromptInputAnchor(textFieldKey, layerLink),
              textController: widget.textController,
              onPageSelected: handlePageSelected,
            );
          },
          child: DecoratedBox(
            decoration: decoration(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        DesktopAIPromptSizes.attachedFilesBarPadding.vertical +
                            DesktopAIPromptSizes.attachedFilesPreviewHeight,
                  ),
                  child: TextFieldTapRegion(
                    child: PromptInputFile(
                      onDeleted: (file) => context
                          .read<AIPromptInputBloc>()
                          .add(AIPromptInputEvent.removeFile(file)),
                    ),
                  ),
                ),
                const VSpace(4.0),
                BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
                  builder: (context, state) {
                    return Stack(
                      children: [
                        ConstrainedBox(
                          constraints: getTextFieldConstraints(
                            state.showPredefinedFormats,
                          ),
                          child: inputTextField(),
                        ),
                        if (state.showPredefinedFormats)
                          Positioned.fill(
                            bottom: null,
                            child: TextFieldTapRegion(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 8.0,
                                ),
                                child: ChangeFormatBar(
                                  showImageFormats: state.aiType.isCloud,
                                  predefinedFormat: state.predefinedFormat,
                                  spacing: 4.0,
                                  onSelectPredefinedFormat: (format) =>
                                      context.read<AIPromptInputBloc>().add(
                                            AIPromptInputEvent
                                                .updatePredefinedFormat(format),
                                          ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          top: null,
                          child: TextFieldTapRegion(
                            child: _PromptBottomActions(
                              showPredefinedFormats:
                                  state.showPredefinedFormats,
                              onTogglePredefinedFormatSection: () =>
                                  context.read<AIPromptInputBloc>().add(
                                        AIPromptInputEvent
                                            .toggleShowPredefinedFormat(),
                                      ),
                              onStartMention: startMentionPageFromButton,
                              sendButtonState: sendButtonState,
                              onSendPressed: handleSend,
                              onStopStreaming: widget.onStopStreaming,
                              selectedSourcesNotifier:
                                  widget.selectedSourcesNotifier,
                              onUpdateSelectedSources:
                                  widget.onUpdateSelectedSources,
                              extraBottomActionButton:
                                  widget.extraBottomActionButton,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration decoration(BuildContext context) {
    if (widget.hideDecoration) {
      return BoxDecoration();
    }
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(
        color: focusNode.hasFocus
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        width: focusNode.hasFocus ? 1.5 : 1.0,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
    );
  }

  void startMentionPageFromButton() {
    if (overlayController.isShowing) {
      return;
    }
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    widget.textController.text += '@';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context
            .read<ChatInputControlCubit>()
            .startSearching(widget.textController.value);
        overlayController.show();
      }
    });
  }

  void cancelMentionPage() {
    if (overlayController.isShowing) {
      inputControlCubit.reset();
      overlayController.hide();
    }
  }

  void updateSendButtonState() {
    if (widget.isStreaming) {
      sendButtonState = SendButtonState.streaming;
    } else if (widget.textController.text.trim().isEmpty) {
      sendButtonState = SendButtonState.disabled;
    } else {
      sendButtonState = SendButtonState.enabled;
    }
  }

  void handleSend() {
    if (widget.isStreaming) {
      return;
    }
    final trimmedText = inputControlCubit.formatIntputText(
      widget.textController.text.trim(),
    );
    widget.textController.clear();
    if (trimmedText.isEmpty) {
      return;
    }

    // get the attached files and mentioned pages
    final metadata = context.read<AIPromptInputBloc>().consumeMetadata();

    final bloc = context.read<AIPromptInputBloc>();
    final showPredefinedFormats = bloc.state.showPredefinedFormats;
    final predefinedFormat = bloc.state.predefinedFormat;

    widget.onSubmitted(
      trimmedText,
      showPredefinedFormats ? predefinedFormat : null,
      metadata,
    );
  }

  void handleTextControllerChanged() {
    setState(() {
      // update whether send button is clickable
      updateSendButtonState();
      isComposing = !widget.textController.value.composing.isCollapsed;
    });

    if (isComposing) {
      return;
    }

    // disable mention
    return;

    // handle text and selection changes ONLY when mentioning a page
    // ignore: dead_code
    if (!overlayController.isShowing ||
        inputControlCubit.filterStartPosition == -1) {
      return;
    }

    // handle cases where mention a page is cancelled
    final textController = widget.textController;
    final textSelection = textController.value.selection;
    final isSelectingMultipleCharacters = !textSelection.isCollapsed;
    final isCaretBeforeStartOfRange =
        textSelection.baseOffset < inputControlCubit.filterStartPosition;
    final isCaretAfterEndOfRange =
        textSelection.baseOffset > inputControlCubit.filterEndPosition;
    final isTextSame = inputControlCubit.inputText == textController.text;

    if (isSelectingMultipleCharacters ||
        isTextSame && (isCaretBeforeStartOfRange || isCaretAfterEndOfRange)) {
      cancelMentionPage();
      return;
    }

    final previousLength = inputControlCubit.inputText.characters.length;
    final currentLength = textController.text.characters.length;

    // delete "@"
    if (previousLength != currentLength && isCaretBeforeStartOfRange) {
      cancelMentionPage();
      return;
    }

    // handle cases where mention the filter is updated
    if (previousLength != currentLength) {
      final diff = currentLength - previousLength;
      final newEndPosition = inputControlCubit.filterEndPosition + diff;
      final newFilter = textController.text.substring(
        inputControlCubit.filterStartPosition,
        newEndPosition,
      );
      inputControlCubit.updateFilter(
        textController.text,
        newFilter,
        newEndPosition: newEndPosition,
      );
    } else if (!isTextSame) {
      final newFilter = textController.text.substring(
        inputControlCubit.filterStartPosition,
        inputControlCubit.filterEndPosition,
      );
      inputControlCubit.updateFilter(textController.text, newFilter);
    }
  }

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event.character == '@') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        inputControlCubit.startSearching(widget.textController.value);
        overlayController.show();
      });
    }
    return KeyEventResult.ignored;
  }

  void handlePageSelected(ViewPB view) {
    final newText = widget.textController.text.replaceRange(
      inputControlCubit.filterStartPosition,
      inputControlCubit.filterEndPosition,
      view.id,
    );
    widget.textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: inputControlCubit.filterStartPosition + view.id.length,
        affinity: TextAffinity.upstream,
      ),
    );

    inputControlCubit.selectPage(view);
    overlayController.hide();
  }

  Widget inputTextField() {
    return Shortcuts(
      shortcuts: buildShortcuts(),
      child: Actions(
        actions: buildActions(),
        child: CompositedTransformTarget(
          link: layerLink,
          child: BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
            builder: (context, state) {
              Widget textField = PromptInputTextField(
                key: textFieldKey,
                editable: state.editable,
                cubit: inputControlCubit,
                textController: widget.textController,
                textFieldFocusNode: focusNode,
                contentPadding:
                    calculateContentPadding(state.showPredefinedFormats),
                hintText: state.hintText,
              );

              if (!state.editable) {
                textField = FlowyTooltip(
                  message: LocaleKeys
                      .settings_aiPage_keys_localAINotReadyTextFieldPrompt
                      .tr(),
                  child: textField,
                );
              }

              return textField;
            },
          ),
        ),
      ),
    );
  }

  BoxConstraints getTextFieldConstraints(bool showPredefinedFormats) {
    double minHeight = DesktopAIPromptSizes.textFieldMinHeight +
        DesktopAIPromptSizes.actionBarSendButtonSize +
        DesktopAIChatSizes.inputActionBarMargin.vertical;
    double maxHeight = 300;
    if (showPredefinedFormats) {
      minHeight += DesktopAIPromptSizes.predefinedFormatButtonHeight;
      maxHeight += DesktopAIPromptSizes.predefinedFormatButtonHeight;
    }
    return BoxConstraints(minHeight: minHeight, maxHeight: maxHeight);
  }

  EdgeInsetsGeometry calculateContentPadding(bool showPredefinedFormats) {
    final top = showPredefinedFormats
        ? DesktopAIPromptSizes.predefinedFormatButtonHeight
        : 0.0;
    final bottom = DesktopAIPromptSizes.actionBarSendButtonSize +
        DesktopAIChatSizes.inputActionBarMargin.vertical;

    return DesktopAIPromptSizes.textFieldContentPadding
        .add(EdgeInsets.only(top: top, bottom: bottom));
  }

  Map<ShortcutActivator, Intent> buildShortcuts() {
    if (isComposing) {
      return const {};
    }

    return const {
      SingleActivator(LogicalKeyboardKey.arrowUp): _FocusPreviousItemIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): _FocusNextItemIntent(),
      SingleActivator(LogicalKeyboardKey.escape): _CancelMentionPageIntent(),
      SingleActivator(LogicalKeyboardKey.enter): _SubmitOrMentionPageIntent(),
    };
  }

  Map<Type, Action<Intent>> buildActions() {
    return {
      _FocusPreviousItemIntent: CallbackAction<_FocusPreviousItemIntent>(
        onInvoke: (intent) {
          inputControlCubit.updateSelectionUp();
          return;
        },
      ),
      _FocusNextItemIntent: CallbackAction<_FocusNextItemIntent>(
        onInvoke: (intent) {
          inputControlCubit.updateSelectionDown();
          return;
        },
      ),
      _CancelMentionPageIntent: CallbackAction<_CancelMentionPageIntent>(
        onInvoke: (intent) {
          cancelMentionPage();
          return;
        },
      ),
      _SubmitOrMentionPageIntent: CallbackAction<_SubmitOrMentionPageIntent>(
        onInvoke: (intent) {
          if (overlayController.isShowing) {
            inputControlCubit.state.maybeWhen(
              ready: (visibleViews, focusedViewIndex) {
                if (focusedViewIndex != -1 &&
                    focusedViewIndex < visibleViews.length) {
                  handlePageSelected(visibleViews[focusedViewIndex]);
                }
              },
              orElse: () {},
            );
          } else {
            handleSend();
          }
          return;
        },
      ),
    };
  }
}

class _SubmitOrMentionPageIntent extends Intent {
  const _SubmitOrMentionPageIntent();
}

class _CancelMentionPageIntent extends Intent {
  const _CancelMentionPageIntent();
}

class _FocusPreviousItemIntent extends Intent {
  const _FocusPreviousItemIntent();
}

class _FocusNextItemIntent extends Intent {
  const _FocusNextItemIntent();
}

class PromptInputTextField extends StatelessWidget {
  const PromptInputTextField({
    super.key,
    required this.editable,
    required this.cubit,
    required this.textController,
    required this.textFieldFocusNode,
    required this.contentPadding,
    this.hintText = "",
  });

  final ChatInputControlCubit cubit;
  final TextEditingController textController;
  final FocusNode textFieldFocusNode;
  final EdgeInsetsGeometry contentPadding;
  final bool editable;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return ExtendedTextField(
      controller: textController,
      focusNode: textFieldFocusNode,
      readOnly: !editable,
      enabled: editable,
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: contentPadding,
        hintText: hintText,
        hintStyle: inputHintTextStyle(context),
        isCollapsed: true,
        isDense: true,
      ),
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      minLines: 1,
      maxLines: null,
      style: Theme.of(context).textTheme.bodyMedium,
      specialTextSpanBuilder: PromptInputTextSpanBuilder(
        inputControlCubit: cubit,
        specialTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  TextStyle? inputHintTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).isLightMode
              ? const Color(0xFFBDC2C8)
              : const Color(0xFF3C3E51),
        );
  }
}

class _PromptBottomActions extends StatelessWidget {
  const _PromptBottomActions({
    required this.sendButtonState,
    required this.showPredefinedFormats,
    required this.onTogglePredefinedFormatSection,
    required this.onStartMention,
    required this.onSendPressed,
    required this.onStopStreaming,
    required this.selectedSourcesNotifier,
    required this.onUpdateSelectedSources,
    this.extraBottomActionButton,
  });

  final bool showPredefinedFormats;
  final void Function() onTogglePredefinedFormatSection;
  final void Function() onStartMention;
  final SendButtonState sendButtonState;
  final void Function() onSendPressed;
  final void Function() onStopStreaming;
  final ValueNotifier<List<String>> selectedSourcesNotifier;
  final void Function(List<String>) onUpdateSelectedSources;
  final Widget? extraBottomActionButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DesktopAIPromptSizes.actionBarSendButtonSize,
      margin: DesktopAIChatSizes.inputActionBarMargin,
      child: BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
        builder: (context, state) {
          return Row(
            children: [
              _predefinedFormatButton(),
              const HSpace(
                DesktopAIChatSizes.inputActionBarButtonSpacing,
              ),
              SelectModelMenu(
                aiModelStateNotifier:
                    context.read<AIPromptInputBloc>().aiModelStateNotifier,
              ),
              const Spacer(),
              if (state.aiType.isCloud) ...[
                _selectSourcesButton(),
                const HSpace(
                  DesktopAIChatSizes.inputActionBarButtonSpacing,
                ),
              ],
              if (extraBottomActionButton != null) ...[
                extraBottomActionButton!,
                const HSpace(
                  DesktopAIChatSizes.inputActionBarButtonSpacing,
                ),
              ],
              // _mentionButton(context),
              // const HSpace(
              //   DesktopAIPromptSizes.actionBarButtonSpacing,
              // ),
              if (state.supportChatWithFile) ...[
                _attachmentButton(context),
                const HSpace(
                  DesktopAIChatSizes.inputActionBarButtonSpacing,
                ),
              ],
              _sendButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _predefinedFormatButton() {
    return PromptInputDesktopToggleFormatButton(
      showFormatBar: showPredefinedFormats,
      onTap: onTogglePredefinedFormatSection,
    );
  }

  Widget _selectSourcesButton() {
    return PromptInputDesktopSelectSourcesButton(
      onUpdateSelectedSources: onUpdateSelectedSources,
      selectedSourcesNotifier: selectedSourcesNotifier,
    );
  }

  // Widget _mentionButton(BuildContext context) {
  //   return PromptInputMentionButton(
  //     iconSize: DesktopAIPromptSizes.actionBarIconSize,
  //     buttonSize: DesktopAIPromptSizes.actionBarButtonSize,
  //     onTap: onStartMention,
  //   );
  // }

  Widget _attachmentButton(BuildContext context) {
    return PromptInputAttachmentButton(
      onTap: () async {
        final path = await getIt<FilePickerService>().pickFiles(
          dialogTitle: '',
          type: FileType.custom,
          allowedExtensions: ["pdf", "txt", "md"],
        );

        if (path == null) {
          return;
        }

        for (final file in path.files) {
          if (file.path != null && context.mounted) {
            context
                .read<AIPromptInputBloc>()
                .add(AIPromptInputEvent.attachFile(file.path!, file.name));
          }
        }
      },
    );
  }

  Widget _sendButton() {
    return PromptInputSendButton(
      state: sendButtonState,
      onSendPressed: onSendPressed,
      onStopStreaming: onStopStreaming,
    );
  }
}

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_control_cubit.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_user_cubit.dart';
import 'package:appflowy/plugins/ai_chat/presentation/layout_define.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'browse_prompts_button.dart';

class DesktopPromptInput extends StatefulWidget {
  final bool isStreaming;

  final AiPromptInputTextEditingController textController;
  final void Function() onStopStreaming;
  final void Function(String, PredefinedFormat?, Map<String, dynamic>)
      onSubmitted;
  final ValueNotifier<List<String>> selectedSourcesNotifier;
  final void Function(List<String>) onUpdateSelectedSources;
  final bool hideDecoration;
  final bool hideFormats;
  final Widget? extraBottomActionButton;

  const DesktopPromptInput({
    super.key,
    required this.isStreaming,
    required this.textController,
    required this.onStopStreaming,
    required this.onSubmitted,
    required this.selectedSourcesNotifier,
    required this.onUpdateSelectedSources,
    this.hideDecoration = false,
    this.hideFormats = false,
    this.extraBottomActionButton,
  });

  @override
  State<DesktopPromptInput> createState() => _DesktopPromptInputState();
}

class PromptInputTextField extends StatelessWidget {
  final ChatInputControlCubit cubit;

  final TextEditingController textController;
  final FocusNode textFieldFocusNode;
  final EdgeInsetsGeometry contentPadding;
  final bool editable;
  final String hintText;

  const PromptInputTextField({
    super.key,
    required this.editable,
    required this.cubit,
    required this.textController,
    required this.textFieldFocusNode,
    required this.contentPadding,
    this.hintText = "",
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return TextField(
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
      style: theme.textStyle.body.standard(
        color: theme.textColorScheme.primary,
      ),
    );
  }

  TextStyle? inputHintTextStyle(BuildContext context) {
    return AppFlowyTheme.of(context).textStyle.body.standard(
          color: Theme.of(context).isLightMode
              ? const Color(0xFFBDC2C8)
              : const Color(0xFF3C3E51),
        );
  }
}

class _CancelMentionPageIntent extends Intent {
  const _CancelMentionPageIntent();
}

class _DesktopPromptInputState extends State<DesktopPromptInput> {
  final textFieldKey = GlobalKey();
  final layerLink = LayerLink();
  final overlayController = OverlayPortalController();
  final inputControlCubit = ChatInputControlCubit();
  final chatUserCubit = ChatUserCubit();
  final focusNode = FocusNode();

  late SendButtonState sendButtonState;
  bool isComposing = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: inputControlCubit),
        BlocProvider.value(value: chatUserCubit),
      ],
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
                            state.showPredefinedFormats && !widget.hideFormats,
                          ),
                          child: inputTextField(),
                        ),
                        if (state.showPredefinedFormats && !widget.hideFormats)
                          Positioned.fill(
                            bottom: null,
                            child: TextFieldTapRegion(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 8.0,
                                ),
                                child: ChangeFormatBar(
                                  showImageFormats:
                                      state.modelState.type == AiType.cloud,
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
                              showPredefinedFormatBar:
                                  state.showPredefinedFormats,
                              showPredefinedFormatButton: !widget.hideFormats,
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
                              onSelectPrompt: handleOnSelectPrompt,
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

  EdgeInsetsGeometry calculateContentPadding(bool showPredefinedFormats) {
    final top = showPredefinedFormats
        ? DesktopAIPromptSizes.predefinedFormatButtonHeight
        : 0.0;
    final bottom = DesktopAIPromptSizes.actionBarSendButtonSize +
        DesktopAIChatSizes.inputActionBarMargin.vertical;

    return DesktopAIPromptSizes.textFieldContentPadding
        .add(EdgeInsets.only(top: top, bottom: bottom));
  }

  void cancelMentionPage() {
    if (overlayController.isShowing) {
      inputControlCubit.reset();
      overlayController.hide();
    }
  }

  void checkForAskingAI() {
    final paletteBloc = context.read<CommandPaletteBloc?>(),
        paletteState = paletteBloc?.state;
    if (paletteBloc == null || paletteState == null) return;
    final isAskingAI = paletteState.askAI;
    if (!isAskingAI) return;
    paletteBloc.add(CommandPaletteEvent.askedAI());
    final query = paletteState.query ?? '';
    if (query.isEmpty) return;
    final sources = (paletteState.askAISources ?? []).map((e) => e.id).toList();
    final metadata =
        context.read<AIPromptInputBloc?>()?.consumeMetadata() ?? {};
    final promptState = context.read<AIPromptInputBloc?>()?.state;
    final predefinedFormat = promptState?.predefinedFormat;
    if (sources.isNotEmpty) {
      widget.onUpdateSelectedSources(sources);
    }
    widget.onSubmitted.call(query, predefinedFormat, metadata);
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
    chatUserCubit.close();
    super.dispose();
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

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    // if (event.character == '@') {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     inputControlCubit.startSearching(widget.textController.value);
    //     overlayController.show();
    //   });
    // }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      node.unfocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void handleOnSelectPrompt(AiPrompt prompt) {
    final bloc = context.read<AIPromptInputBloc>();
    bloc.add(
      AIPromptInputEvent.updateMentionedViews([]),
    );

    final content = AiPromptInputTextEditingController.replace(prompt.content);

    widget.textController.value = TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(
        offset: content.length,
      ),
    );

    if (bloc.state.showPredefinedFormats) {
      bloc.add(
        AIPromptInputEvent.toggleShowPredefinedFormat(),
      );
    }
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

  void handleSend() {
    if (widget.isStreaming) {
      return;
    }
    String userInput = widget.textController.text.trim();
    userInput = inputControlCubit.formatIntputText(userInput);
    userInput = AiPromptInputTextEditingController.restore(userInput);

    widget.textController.clear();
    if (userInput.isEmpty) {
      return;
    }

    // get the attached files and mentioned pages
    final metadata = context.read<AIPromptInputBloc>().consumeMetadata();

    final bloc = context.read<AIPromptInputBloc>();
    final showPredefinedFormats = bloc.state.showPredefinedFormats;
    final predefinedFormat = bloc.state.predefinedFormat;

    widget.onSubmitted(
      userInput,
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

  @override
  void initState() {
    super.initState();

    widget.textController.addListener(handleTextControllerChanged);
    focusNode
      ..addListener(
        () {
          if (!widget.hideDecoration) {
            setState(() {}); // refresh border color
          }
          if (!focusNode.hasFocus) {
            cancelMentionPage(); // hide menu when lost focus
          }
        },
      )
      ..onKeyEvent = handleKeyEvent;

    updateSendButtonState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
      checkForAskingAI();
    });
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
                editable: state.modelState.isEditable,
                cubit: inputControlCubit,
                textController: widget.textController,
                textFieldFocusNode: focusNode,
                contentPadding:
                    calculateContentPadding(state.showPredefinedFormats),
                hintText: state.modelState.hintText,
              );

              if (state.modelState.tooltip != null) {
                textField = FlowyTooltip(
                  message: state.modelState.tooltip!,
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

  void updateSendButtonState() {
    if (widget.isStreaming) {
      sendButtonState = SendButtonState.streaming;
    } else if (widget.textController.text.trim().isEmpty) {
      sendButtonState = SendButtonState.disabled;
    } else {
      sendButtonState = SendButtonState.enabled;
    }
  }
}

class _FocusNextItemIntent extends Intent {
  const _FocusNextItemIntent();
}

class _FocusPreviousItemIntent extends Intent {
  const _FocusPreviousItemIntent();
}

class _PromptBottomActions extends StatelessWidget {
  final bool showPredefinedFormatBar;

  final bool showPredefinedFormatButton;
  final void Function() onTogglePredefinedFormatSection;
  final void Function() onStartMention;
  final SendButtonState sendButtonState;
  final void Function() onSendPressed;
  final void Function() onStopStreaming;
  final ValueNotifier<List<String>> selectedSourcesNotifier;
  final void Function(List<String>) onUpdateSelectedSources;
  final void Function(AiPrompt) onSelectPrompt;
  final Widget? extraBottomActionButton;
  const _PromptBottomActions({
    required this.sendButtonState,
    required this.showPredefinedFormatBar,
    required this.showPredefinedFormatButton,
    required this.onTogglePredefinedFormatSection,
    required this.onStartMention,
    required this.onSendPressed,
    required this.onStopStreaming,
    required this.selectedSourcesNotifier,
    required this.onUpdateSelectedSources,
    required this.onSelectPrompt,
    this.extraBottomActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DesktopAIPromptSizes.actionBarSendButtonSize,
      margin: DesktopAIChatSizes.inputActionBarMargin,
      child: BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
        builder: (context, state) {
          return Row(
            spacing: DesktopAIChatSizes.inputActionBarButtonSpacing,
            children: [
              if (showPredefinedFormatButton) _predefinedFormatButton(),
              _selectModelButton(context),
              _buildBrowsePromptsButton(),

              const Spacer(),

              if (context.read<ChatUserCubit>().supportSelectSource())
                _selectSourcesButton(),

              if (extraBottomActionButton != null) extraBottomActionButton!,
              // _mentionButton(context),
              if (state.supportChatWithFile) _attachmentButton(context),
              _sendButton(),
            ],
          );
        },
      ),
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

  Widget _buildBrowsePromptsButton() {
    return BrowsePromptsButton(
      onSelectPrompt: onSelectPrompt,
    );
  }

  Widget _predefinedFormatButton() {
    return PromptInputDesktopToggleFormatButton(
      showFormatBar: showPredefinedFormatBar,
      onTap: onTogglePredefinedFormatSection,
    );
  }

  Widget _selectModelButton(BuildContext context) {
    return SelectModelMenu(
      aiModelStateNotifier:
          context.read<AIPromptInputBloc>().aiModelStateNotifier,
    );
  }

  Widget _selectSourcesButton() {
    return PromptInputDesktopSelectSourcesButton(
      onUpdateSelectedSources: onUpdateSelectedSources,
      selectedSourcesNotifier: selectedSourcesNotifier,
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

class _SubmitOrMentionPageIntent extends Intent {
  const _SubmitOrMentionPageIntent();
}

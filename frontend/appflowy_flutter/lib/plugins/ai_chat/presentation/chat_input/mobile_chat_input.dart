import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_control_cubit.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileChatInput extends StatefulWidget {
  const MobileChatInput({
    super.key,
    required this.isStreaming,
    required this.onStopStreaming,
    required this.onSubmitted,
    required this.selectedSourcesNotifier,
    required this.onUpdateSelectedSources,
  });

  final bool isStreaming;
  final void Function() onStopStreaming;
  final ValueNotifier<List<String>> selectedSourcesNotifier;
  final void Function(String, PredefinedFormat?, Map<String, dynamic>)
      onSubmitted;
  final void Function(List<String>) onUpdateSelectedSources;

  @override
  State<MobileChatInput> createState() => _MobileChatInputState();
}

class _MobileChatInputState extends State<MobileChatInput> {
  final inputControlCubit = ChatInputControlCubit();
  final focusNode = FocusNode();
  final textController = TextEditingController();

  late SendButtonState sendButtonState;

  @override
  void initState() {
    super.initState();

    textController.addListener(handleTextControllerChanged);
    // focusNode.onKeyEvent = handleKeyEvent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    updateSendButtonState();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    updateSendButtonState();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    focusNode.dispose();
    textController.dispose();
    inputControlCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "ai_chat_prompt",
      child: BlocProvider.value(
        value: inputControlCubit,
        child: BlocListener<ChatInputControlCubit, ChatInputControlState>(
          listener: (context, state) {
            state.maybeWhen(
              updateSelectedViews: (selectedViews) {
                context.read<AIPromptInputBloc>().add(
                      AIPromptInputEvent.updateMentionedViews(selectedViews),
                    );
              },
              orElse: () {},
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4.0,
                  offset: Offset(0, -2),
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                ),
              ],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8.0)),
            ),
            child: BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MobileAIPromptSizes
                                .attachedFilesBarPadding.vertical +
                            MobileAIPromptSizes.attachedFilesPreviewHeight,
                      ),
                      child: PromptInputFile(
                        onDeleted: (file) => context
                            .read<AIPromptInputBloc>()
                            .add(AIPromptInputEvent.removeFile(file)),
                      ),
                    ),
                    if (state.showPredefinedFormats)
                      TextFieldTapRegion(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ChangeFormatBar(
                            predefinedFormat: state.predefinedFormat,
                            spacing: 8.0,
                            onSelectPredefinedFormat: (format) =>
                                context.read<AIPromptInputBloc>().add(
                                      AIPromptInputEvent.updatePredefinedFormat(
                                        format,
                                      ),
                                    ),
                          ),
                        ),
                      )
                    else
                      const VSpace(8.0),
                    inputTextField(context),
                    TextFieldTapRegion(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const HSpace(8.0),
                            leadingButtons(
                              context,
                              state.showPredefinedFormats,
                            ),
                            const Spacer(),
                            sendButton(),
                            const HSpace(12.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void updateSendButtonState() {
    if (widget.isStreaming) {
      sendButtonState = SendButtonState.streaming;
    } else if (textController.text.trim().isEmpty) {
      sendButtonState = SendButtonState.disabled;
    } else {
      sendButtonState = SendButtonState.enabled;
    }
  }

  void handleSendPressed() {
    if (widget.isStreaming) {
      return;
    }
    final trimmedText = inputControlCubit.formatIntputText(
      textController.text.trim(),
    );
    textController.clear();
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
    if (textController.value.isComposingRangeValid) {
      return;
    }
    // inputControlCubit.updateInputText(textController.text);
    setState(() => updateSendButtonState());
  }

  // KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
  //   if (event.character == '@') {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       mentionPage(context);
  //     });
  //   }
  //   return KeyEventResult.ignored;
  // }

  Future<void> mentionPage(BuildContext context) async {
    // if the focus node is on focus, unfocus it for better animation
    // otherwise, the page sheet animation will be blocked by the keyboard
    inputControlCubit.refreshViews();
    inputControlCubit.startSearching(textController.value);
    if (focusNode.hasFocus) {
      focusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (context.mounted) {
      final selectedView = await showPageSelectorSheet(
        context,
        filter: (view) =>
            !view.isSpace &&
            view.layout.isDocumentView &&
            view.parentViewId != view.id &&
            !inputControlCubit.selectedViewIds.contains(view.id),
      );
      if (selectedView != null) {
        final newText = textController.text.replaceRange(
          inputControlCubit.filterStartPosition,
          inputControlCubit.filterStartPosition,
          selectedView.id,
        );
        textController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset:
                textController.selection.baseOffset + selectedView.id.length,
            affinity: TextAffinity.upstream,
          ),
        );

        inputControlCubit.selectPage(selectedView);
      }
      focusNode.requestFocus();
      inputControlCubit.reset();
    }
  }

  Widget inputTextField(BuildContext context) {
    return BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
      builder: (context, state) {
        return ExtendedTextField(
          controller: textController,
          focusNode: focusNode,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: MobileAIPromptSizes.textFieldContentPadding,
            hintText: state.modelState.hintText,
            hintStyle: inputHintTextStyle(context),
            isCollapsed: true,
            isDense: true,
          ),
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          minLines: 1,
          maxLines: null,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(height: 20 / 14),
          specialTextSpanBuilder: PromptInputTextSpanBuilder(
            inputControlCubit: inputControlCubit,
            specialTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          onTapOutside: (_) => focusNode.unfocus(),
        );
      },
    );
  }

  TextStyle? inputHintTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).isLightMode
              ? const Color(0xFFBDC2C8)
              : const Color(0xFF3C3E51),
        );
  }

  Widget leadingButtons(BuildContext context, bool showPredefinedFormats) {
    return _LeadingActions(
      // onMention: () {
      //   textController.text += '@';
      //   if (!focusNode.hasFocus) {
      //     focusNode.requestFocus();
      //   }
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     mentionPage(context);
      //   });
      // },
      showPredefinedFormats: showPredefinedFormats,
      onTogglePredefinedFormatSection: () {
        context
            .read<AIPromptInputBloc>()
            .add(AIPromptInputEvent.toggleShowPredefinedFormat());
      },
      selectedSourcesNotifier: widget.selectedSourcesNotifier,
      onUpdateSelectedSources: widget.onUpdateSelectedSources,
    );
  }

  Widget sendButton() {
    return PromptInputSendButton(
      state: sendButtonState,
      onSendPressed: handleSendPressed,
      onStopStreaming: widget.onStopStreaming,
    );
  }
}

class _LeadingActions extends StatelessWidget {
  const _LeadingActions({
    required this.showPredefinedFormats,
    required this.onTogglePredefinedFormatSection,
    required this.selectedSourcesNotifier,
    required this.onUpdateSelectedSources,
  });

  final bool showPredefinedFormats;
  final void Function() onTogglePredefinedFormatSection;
  final ValueNotifier<List<String>> selectedSourcesNotifier;
  final void Function(List<String>) onUpdateSelectedSources;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SeparatedRow(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => const HSpace(4.0),
        children: [
          PromptInputMobileSelectSourcesButton(
            selectedSourcesNotifier: selectedSourcesNotifier,
            onUpdateSelectedSources: onUpdateSelectedSources,
          ),
          PromptInputMobileToggleFormatButton(
            showFormatBar: showPredefinedFormats,
            onTap: onTogglePredefinedFormatSection,
          ),
        ],
      ),
    );
  }
}

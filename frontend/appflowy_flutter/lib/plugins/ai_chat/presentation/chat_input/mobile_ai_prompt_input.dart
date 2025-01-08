import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_prompt_input_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_control_cubit.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../layout_define.dart';
import 'ai_prompt_buttons.dart';
import 'chat_input_file.dart';
import 'chat_input_span.dart';
import 'chat_mention_page_bottom_sheet.dart';
import 'predefined_format_buttons.dart';
import 'select_sources_bottom_sheet.dart';

class MobileAIPromptInput extends StatefulWidget {
  const MobileAIPromptInput({
    super.key,
    required this.chatId,
    required this.isStreaming,
    required this.onStopStreaming,
    required this.onSubmitted,
    required this.onUpdateSelectedSources,
  });

  final String chatId;
  final bool isStreaming;
  final void Function() onStopStreaming;
  final void Function(String, PredefinedFormat?, Map<String, dynamic>)
      onSubmitted;
  final void Function(List<String>) onUpdateSelectedSources;

  @override
  State<MobileAIPromptInput> createState() => _MobileAIPromptInputState();
}

class _MobileAIPromptInputState extends State<MobileAIPromptInput> {
  final inputControlCubit = ChatInputControlCubit();
  final focusNode = FocusNode();
  final textController = TextEditingController();

  bool showPredefinedFormatSection = false;
  PredefinedFormat predefinedFormat = const PredefinedFormat.auto();
  late SendButtonState sendButtonState;

  @override
  void initState() {
    super.initState();

    textController.addListener(handleTextControllerChange);
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
              borderRadius: MobileAIPromptSizes.promptFrameRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MobileAIPromptSizes.attachedFilesBarPadding.vertical +
                            MobileAIPromptSizes.attachedFilesPreviewHeight,
                  ),
                  child: ChatInputFile(
                    chatId: widget.chatId,
                    onDeleted: (file) => context
                        .read<AIPromptInputBloc>()
                        .add(AIPromptInputEvent.removeFile(file)),
                  ),
                ),
                if (showPredefinedFormatSection)
                  TextFieldTapRegion(
                    child: Container(
                      padding: MobileAIPromptSizes.predefinedFormatBarPadding,
                      child: ChangeFormatBar(
                        predefinedFormat: predefinedFormat,
                        spacing: MobileAIPromptSizes
                            .predefinedFormatBarButtonSpacing,
                        iconSize:
                            MobileAIPromptSizes.predefinedFormatIconHeight,
                        buttonSize:
                            MobileAIPromptSizes.predefinedFormatButtonHeight,
                        onSelectPredefinedFormat: (format) {
                          setState(() => predefinedFormat = format);
                        },
                      ),
                    ),
                  ),
                inputTextField(context),
                Row(
                  children: [
                    const HSpace(8.0),
                    leadingButtons(context),
                    const Spacer(),
                    sendButton(),
                    const HSpace(12.0),
                  ],
                ),
              ],
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

    widget.onSubmitted(
      trimmedText,
      showPredefinedFormatSection ? predefinedFormat : null,
      metadata,
    );
  }

  void handleTextControllerChange() {
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
            hintText: switch (state.aiType) {
              AIType.appflowyAI => LocaleKeys.chat_inputMessageHint.tr(),
              AIType.localAI => LocaleKeys.chat_inputLocalAIMessageHint.tr()
            },
            isCollapsed: true,
            isDense: true,
          ),
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          minLines: 1,
          maxLines: null,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(height: 20 / 14),
          specialTextSpanBuilder: ChatInputTextSpanBuilder(
            inputControlCubit: inputControlCubit,
            specialTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
    );
  }

  Widget leadingButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _LeadingActions(
        // onMention: () {
        //   textController.text += '@';
        //   if (!focusNode.hasFocus) {
        //     focusNode.requestFocus();
        //   }
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     mentionPage(context);
        //   });
        // },
        showPredefinedFormatSection: showPredefinedFormatSection,
        predefinedFormat: predefinedFormat,
        onTogglePredefinedFormatSection: () {
          setState(() {
            showPredefinedFormatSection = !showPredefinedFormatSection;
            if (!showPredefinedFormatSection) {
              predefinedFormat = const PredefinedFormat.auto();
            }
          });
        },
        onUpdateSelectedSources: widget.onUpdateSelectedSources,
      ),
    );
  }

  Widget sendButton() {
    return Container(
      alignment: Alignment.bottomCenter,
      child: PromptInputSendButton(
        buttonSize: MobileAIPromptSizes.sendButtonSize,
        iconSize: MobileAIPromptSizes.sendButtonSize,
        onSendPressed: handleSendPressed,
        onStopStreaming: widget.onStopStreaming,
        state: sendButtonState,
      ),
    );
  }
}

class _LeadingActions extends StatelessWidget {
  const _LeadingActions({
    required this.showPredefinedFormatSection,
    required this.predefinedFormat,
    required this.onTogglePredefinedFormatSection,
    required this.onUpdateSelectedSources,
  });

  final bool showPredefinedFormatSection;
  final PredefinedFormat predefinedFormat;
  final void Function() onTogglePredefinedFormatSection;
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
            onUpdateSelectedSources: onUpdateSelectedSources,
          ),
          PromptInputMobileToggleFormatButton(
            showFormatBar: showPredefinedFormatSection,
            onTap: onTogglePredefinedFormatSection,
          ),
        ],
      ),
    );
  }
}

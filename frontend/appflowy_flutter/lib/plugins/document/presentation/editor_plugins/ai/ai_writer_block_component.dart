import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/ai_markdown_text.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import 'operations/ai_writer_cubit.dart';
import 'operations/ai_writer_entities.dart';
import 'operations/ai_writer_node_extension.dart';
import 'widgets/ai_writer_suggestion_actions.dart';
import 'widgets/ai_writer_prompt_input_more_button.dart';

class AiWriterBlockKeys {
  const AiWriterBlockKeys._();

  static const String type = 'ai_writer';

  static const String isInitialized = 'is_initialized';
  static const String selection = 'selection';
  static const String command = 'command';

  /// Sample usage:
  ///
  /// `attributes: {
  ///   'ai_writer_delta_suggestion': 'original'
  /// }`
  static const String suggestion = 'ai_writer_delta_suggestion';
  static const String suggestionOriginal = 'original';
  static const String suggestionReplacement = 'replacement';
}

Node aiWriterNode({
  required Selection? selection,
  required AiWriterCommand command,
}) {
  return Node(
    type: AiWriterBlockKeys.type,
    attributes: {
      AiWriterBlockKeys.isInitialized: false,
      AiWriterBlockKeys.selection: selection?.toJson(),
      AiWriterBlockKeys.command: command.index,
    },
  );
}

class AIWriterBlockComponentBuilder extends BlockComponentBuilder {
  AIWriterBlockComponentBuilder();

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return AiWriterBlockComponent(
      key: node.key,
      node: node,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
      actionTrailingBuilder: (context, state) => actionTrailingBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  BlockComponentValidate get validate => (node) =>
      node.children.isEmpty &&
      node.attributes[AiWriterBlockKeys.isInitialized] is bool &&
      node.attributes[AiWriterBlockKeys.selection] is Map? &&
      node.attributes[AiWriterBlockKeys.command] is int;
}

class AiWriterBlockComponent extends BlockComponentStatefulWidget {
  const AiWriterBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<AiWriterBlockComponent> createState() => _AIWriterBlockComponentState();
}

class _AIWriterBlockComponentState extends State<AiWriterBlockComponent> {
  final textController = TextEditingController();
  final overlayController = OverlayPortalController();
  final layerLink = LayerLink();

  late final editorState = context.read<EditorState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlayController.show();
      if (!widget.node.isAiWriterInitialized) {
        context.read<AiWriterCubit>().register(widget.node);
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMobile) {
      return const SizedBox.shrink();
    }

    final documentId = context.read<DocumentBloc?>()?.documentId;

    return BlocProvider(
      create: (_) => AIPromptInputBloc(
        predefinedFormat: null,
        objectId: documentId ?? editorState.document.root.id,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OverlayPortal(
            controller: overlayController,
            overlayChildBuilder: (context) {
              return Center(
                child: CompositedTransformFollower(
                  link: layerLink,
                  showWhenUnlinked: false,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 40.0,
                      bottom: 16.0,
                    ),
                    width: constraints.maxWidth,
                    child: OverlayContent(
                      editorState: editorState,
                      node: widget.node,
                    ),
                  ),
                ),
              );
            },
            child: CompositedTransformTarget(
              link: layerLink,
              child: BlocBuilder<AiWriterCubit, AiWriterState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: 1.0,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class OverlayContent extends StatefulWidget {
  const OverlayContent({
    super.key,
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  @override
  State<OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<OverlayContent> {
  final showCommandsToggle = ValueNotifier(false);

  @override
  void dispose() {
    showCommandsToggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiWriterCubit, AiWriterState>(
      builder: (context, state) {
        if (state is IdleAiWriterState) {
          return const SizedBox.shrink();
        }
        final selection = widget.node.aiWriterSelection;
        final showSuggestionPopup =
            state is ReadyAiWriterState && !state.isFirstRun;
        final isInitialReadyState =
            state is ReadyAiWriterState && state.isFirstRun;
        final markdownText = switch (state) {
          final ReadyAiWriterState ready => ready.markdownText,
          final GeneratingAiWriterState generating => generating.markdownText,
          _ => '',
        };
        final hasSelection = selection != null && !selection.isCollapsed;

        final isLightMode = Theme.of(context).isLightMode;
        final darkBorderColor =
            isLightMode ? Color(0x1F1F2329) : Color(0xFF505469);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSuggestionPopup &&
                state.command != AiWriterCommand.explain) ...[
              Container(
                padding: EdgeInsets.all(4.0),
                decoration: _getModalDecoration(
                  context,
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  borderColor: darkBorderColor,
                ),
                child: SuggestionActionBar(
                  currentCommand: state.command,
                  hasSelection: hasSelection,
                  onTap: (action) {
                    _onSelectSuggestionAction(context, action);
                  },
                ),
              ),
              const VSpace(4.0 + 1.0),
            ],
            DecoratedBox(
              decoration: _getModalDecoration(
                context,
                color: null,
                borderColor: darkBorderColor,
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              child: Column(
                children: [
                  if (markdownText.isNotEmpty) ...[
                    DecoratedBox(
                      decoration: _getHelperChildDecoration(context),
                      child: Container(
                        constraints: BoxConstraints(maxHeight: 140),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: ClampingScrollPhysics(),
                                padding: EdgeInsets.only(top: 8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 24.0,
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 6.0),
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: FlowyText(
                                        (state as RegisteredAiWriter)
                                            .command
                                            .i18n,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF666D76),
                                      ),
                                    ),
                                    const VSpace(4.0),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 6.0),
                                      child: AIMarkdownText(
                                        markdown: markdownText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (showSuggestionPopup &&
                                state.command == AiWriterCommand.explain) ...[
                              const VSpace(4.0),
                              SuggestionActionBar(
                                currentCommand: state.command,
                                hasSelection: hasSelection,
                                onTap: (action) {
                                  _onSelectSuggestionAction(context, action);
                                },
                              ),
                            ],
                            const VSpace(8.0),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                    ),
                  ],
                  DecoratedBox(
                    decoration: markdownText.isNotEmpty
                        ? _getInputChildDecoration(context)
                        : _getSingleChildDeocoration(context),
                    child: MainContentArea(
                      isDocumentEmpty: _isDocumentEmpty(),
                      isInitialReadyState: isInitialReadyState,
                      showCommandsToggle: showCommandsToggle,
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: showCommandsToggle,
              builder: (context, value, child) {
                if (!value || !isInitialReadyState) {
                  return const SizedBox.shrink();
                }
                return Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: BottomCommandButtons(
                    hasSelection: hasSelection,
                    editorState: widget.editorState,
                    onSelectCommand: (command) {
                      final promptInputBloc = context.read<AIPromptInputBloc>();
                      final showPredefinedFormats =
                          promptInputBloc.state.showPredefinedFormats;
                      final predefinedFormat =
                          promptInputBloc.state.predefinedFormat;

                      context.read<AiWriterCubit>().runCommand(
                            command,
                            predefinedFormat:
                                showPredefinedFormats ? predefinedFormat : null,
                            isFirstRun: true,
                          );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  BoxDecoration _getModalDecoration(
    BuildContext context, {
    required Color? color,
    required Color borderColor,
    required BorderRadius borderRadius,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(
        color: borderColor,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
      borderRadius: borderRadius,
      boxShadow: const [
        BoxShadow(
          offset: Offset(0, 4),
          blurRadius: 20,
          color: Color(0x1A1F2329),
        ),
      ],
    );
  }

  BoxDecoration _getSingleChildDeocoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    );
  }

  BoxDecoration _getHelperChildDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
    );
  }

  BoxDecoration _getInputChildDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0)),
    );
  }

  void _onSelectSuggestionAction(
    BuildContext context,
    SuggestionAction action,
  ) {
    final predefinedFormat =
        context.read<AIPromptInputBloc>().state.predefinedFormat;
    context.read<AiWriterCubit>().runResponseAction(
          action,
          predefinedFormat,
        );
  }

  bool _isDocumentEmpty() {
    if (widget.editorState.isEmptyForContinueWriting()) {
      final documentContext = widget.editorState.document.root.context;
      if (documentContext == null) {
        return true;
      }
      final view = documentContext.read<ViewBloc>().state.view;
      if (view.name.isEmpty) {
        return true;
      }
    }
    return false;
  }
}

class MainContentArea extends StatelessWidget {
  const MainContentArea({
    super.key,
    required this.isInitialReadyState,
    required this.isDocumentEmpty,
    required this.showCommandsToggle,
  });

  final bool isInitialReadyState;
  final bool isDocumentEmpty;
  final ValueNotifier<bool> showCommandsToggle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiWriterCubit, AiWriterState>(
      builder: (context, state) {
        final cubit = context.read<AiWriterCubit>();

        if (state is ReadyAiWriterState) {
          return DesktopPromptInput(
            isStreaming: false,
            hideDecoration: true,
            onSubmitted: (message, format, _) => cubit.submit(message, format),
            onStopStreaming: () => cubit.stopStream(),
            selectedSourcesNotifier: cubit.selectedSourcesNotifier,
            onUpdateSelectedSources: (sources) {
              cubit.selectedSourcesNotifier.value = [
                ...sources,
              ];
            },
            extraBottomActionButton: isInitialReadyState
                ? ValueListenableBuilder(
                    valueListenable: showCommandsToggle,
                    builder: (context, value, _) {
                      return AiWriterPromptMoreButton(
                        isEnabled: !isDocumentEmpty,
                        isSelected: value,
                        onTap: () => showCommandsToggle.value = !value,
                      );
                    },
                  )
                : null,
          );
        }
        if (state is GeneratingAiWriterState) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const HSpace(6.0),
                Expanded(
                  child: AILoadingIndicator(
                    text: state.command == AiWriterCommand.explain
                        ? LocaleKeys.ai_analyzing.tr()
                        : LocaleKeys.ai_editing.tr(),
                  ),
                ),
                const HSpace(8.0),
                PromptInputSendButton(
                  state: SendButtonState.streaming,
                  onSendPressed: () {},
                  onStopStreaming: () => cubit.stopStream(),
                ),
              ],
            ),
          );
        }
        if (state is ErrorAiWriterState) {
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                const FlowySvg(
                  FlowySvgs.toast_error_filled_s,
                  blendMode: null,
                ),
                const HSpace(8.0),
                Expanded(
                  child: FlowyText(
                    state.error.message,
                    maxLines: null,
                  ),
                ),
                const HSpace(8.0),
                FlowyIconButton(
                  width: 32,
                  hoverColor: Colors.transparent,
                  icon: FlowySvg(
                    FlowySvgs.toast_close_s,
                    size: Size.square(20),
                  ),
                  onPressed: () => cubit.exit(),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

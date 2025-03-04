import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/ai_markdown_text.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/colorscheme/default_colorscheme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import 'operations/ai_writer_cubit.dart';
import 'operations/ai_writer_entities.dart';
import 'operations/ai_writer_node_extension.dart';
import 'suggestion_action_bar.dart';

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
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<AiWriterBlockComponent> createState() => _AIWriterBlockComponentState();
}

class _AIWriterBlockComponentState extends State<AiWriterBlockComponent> {
  final key = GlobalKey();
  final textController = TextEditingController();
  final textFieldFocusNode = FocusNode();
  final overlayController = OverlayPortalController();
  final layerLink = LayerLink();

  late final editorState = context.read<EditorState>();
  late final aiWriterCubit = AiWriterCubit(
    documentId: context.read<DocumentBloc>().documentId,
    editorState: editorState,
    getAiWriterNode: () => widget.node,
    initialCommand: widget.node.aiWriterCommand,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlayController.show();
      textFieldFocusNode.requestFocus();
      if (!widget.node.isAiWriterInitialized) {
        aiWriterCubit.init();
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    textFieldFocusNode.dispose();
    aiWriterCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMobile) {
      return const SizedBox.shrink();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: aiWriterCubit,
        ),
        BlocProvider(
          create: (_) => AIPromptInputBloc(
            predefinedFormat: null,
          ),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return BlocListener<AiWriterCubit, AiWriterState>(
            listener: (context, state) {
              if (state is SingleShotAiWriterState) {
                showConfirmDialog(
                  context: context,
                  title: state.title,
                  description: state.description,
                  onConfirm: state.onDismiss,
                );
              }
            },
            child: OverlayPortal(
              controller: overlayController,
              overlayChildBuilder: (context) {
                return Stack(
                  children: [
                    BlocBuilder<AiWriterCubit, AiWriterState>(
                      builder: (context, state) {
                        final hitTestBehavior = state is GeneratingAiWriterState
                            ? HitTestBehavior.opaque
                            : HitTestBehavior.translucent;
                        return GestureDetector(
                          behavior: hitTestBehavior,
                          onTap: () => onTapOutside(),
                          onTapDown: (_) => onTapOutside(),
                        );
                      },
                    ),
                    CompositedTransformFollower(
                      link: layerLink,
                      showWhenUnlinked: false,
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 40.0,
                          bottom: 16.0,
                        ),
                        width: constraints.maxWidth,
                        child: OverlayContent(
                          node: widget.node,
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: CompositedTransformTarget(
                link: layerLink,
                child: BlocBuilder<AiWriterCubit, AiWriterState>(
                  builder: (context, state) {
                    return SizedBox(
                      key: key,
                      width: double.infinity,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void onTapOutside() {
    if (aiWriterCubit.hasUnusedResponse()) {
      showConfirmDialog(
        context: context,
        title: LocaleKeys.button_discard.tr(),
        description: LocaleKeys.document_plugins_discardResponse.tr(),
        confirmLabel: LocaleKeys.button_discard.tr(),
        style: ConfirmPopupStyle.cancelAndOk,
        onConfirm: () => aiWriterCubit
          ..stopStream()
          ..exit(),
        onCancel: () {},
      );
    } else {
      aiWriterCubit
        ..stopStream()
        ..exit();
    }
  }
}

class OverlayContent extends StatelessWidget {
  const OverlayContent({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiWriterCubit, AiWriterState>(
      builder: (context, state) {
        final selection = node.aiWriterSelection;
        final showSuggestionPopup =
            state is ReadyAiWriterState && !state.isFirstRun;
        final showActionPopup = state is ReadyAiWriterState && state.isFirstRun;
        final markdownText = switch (state) {
          final ReadyAiWriterState ready => ready.markdownText,
          final GeneratingAiWriterState generating => generating.markdownText,
          _ => '',
        };
        final hasSelection = selection != null && !selection.isCollapsed;

        final isLightMode = Theme.of(context).isLightMode;
        final darkBorderColor =
            isLightMode ? Color(0x1F1F2329) : Color(0xFF505469);
        final lightBorderColor =
            Theme.of(context).brightness == Brightness.light
                ? ColorSchemeConstants.lightBorderColor
                : ColorSchemeConstants.darkBorderColor;

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
                  actions: _getSuggestedActions(
                    currentCommand: state.command,
                    hasSelection: hasSelection,
                  ),
                  onTap: (action) {
                    context.read<AiWriterCubit>().runResponseAction(action);
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
                                        state.command.i18n,
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
                            if (showSuggestionPopup) ...[
                              const VSpace(4.0),
                              SuggestionActionBar(
                                actions: _getSuggestedActions(
                                  currentCommand: state.command,
                                  hasSelection: hasSelection,
                                ),
                                onTap: (action) {
                                  context
                                      .read<AiWriterCubit>()
                                      .runResponseAction(action);
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
                    child: MainContentArea(),
                  ),
                ],
              ),
            ),
            if (showActionPopup) ...[
              const VSpace(4.0 + 1.0),
              Container(
                padding: EdgeInsets.all(8.0),
                constraints: BoxConstraints(minWidth: 240.0),
                decoration: _getModalDecoration(
                  context,
                  color: Theme.of(context).colorScheme.surface,
                  borderColor: lightBorderColor,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                child: IntrinsicWidth(
                  child: SeparatedColumn(
                    separatorBuilder: () => const VSpace(4.0),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _getCommands(
                      hasSelection: hasSelection,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _bottomButton(AiWriterCommand command) {
    return Builder(
      builder: (context) {
        return SizedBox(
          height: 30.0,
          child: FlowyButton(
            leftIcon: FlowySvg(
              command.icon,
              size: const Size.square(16),
              color: Theme.of(context).iconTheme.color,
            ),
            margin: const EdgeInsets.all(6.0),
            text: FlowyText(
              command.i18n,
              figmaLineHeight: 20,
            ),
            onTap: () {
              final aiInputBloc = context.read<AIPromptInputBloc>();
              final showPredefinedFormats =
                  aiInputBloc.state.showPredefinedFormats;
              final predefinedFormat = aiInputBloc.state.predefinedFormat;

              context.read<AiWriterCubit>().runCommand(
                    command,
                    showPredefinedFormats ? predefinedFormat : null,
                  );
            },
          ),
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

  List<Widget> _getCommands({required bool hasSelection}) {
    if (hasSelection) {
      return [
        _bottomButton(AiWriterCommand.improveWriting),
        _bottomButton(AiWriterCommand.fixSpellingAndGrammar),
        _bottomButton(AiWriterCommand.explain),
        const Divider(height: 1.0, thickness: 1.0),
        _bottomButton(AiWriterCommand.makeLonger),
        _bottomButton(AiWriterCommand.makeShorter),
      ];
    } else {
      return [
        _bottomButton(AiWriterCommand.continueWriting),
      ];
    }
  }

  List<SuggestionAction> _getSuggestedActions({
    required AiWriterCommand currentCommand,
    required bool hasSelection,
  }) {
    if (hasSelection) {
      return switch (currentCommand) {
        AiWriterCommand.userQuestion || AiWriterCommand.continueWriting => [
            SuggestionAction.keep,
            SuggestionAction.discard,
            SuggestionAction.rewrite,
          ],
        AiWriterCommand.explain => [
            SuggestionAction.insertBelow,
            SuggestionAction.tryAgain,
            SuggestionAction.close,
          ],
        AiWriterCommand.fixSpellingAndGrammar ||
        AiWriterCommand.improveWriting ||
        AiWriterCommand.makeShorter ||
        AiWriterCommand.makeLonger =>
          [
            SuggestionAction.accept,
            SuggestionAction.discard,
            SuggestionAction.insertBelow,
            SuggestionAction.rewrite,
          ],
      };
    } else {
      return switch (currentCommand) {
        AiWriterCommand.userQuestion || AiWriterCommand.continueWriting => [
            SuggestionAction.keep,
            SuggestionAction.discard,
            SuggestionAction.rewrite,
          ],
        AiWriterCommand.explain => [
            SuggestionAction.insertBelow,
            SuggestionAction.tryAgain,
            SuggestionAction.close,
          ],
        _ => [
            SuggestionAction.keep,
            SuggestionAction.discard,
            SuggestionAction.rewrite,
          ],
      };
    }
  }
}

class MainContentArea extends StatelessWidget {
  const MainContentArea({super.key});

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

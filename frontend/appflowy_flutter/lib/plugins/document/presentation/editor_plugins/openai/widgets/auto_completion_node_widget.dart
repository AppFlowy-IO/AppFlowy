import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/build_context_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/text_robot.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/discard_dialog.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/user/application/ai_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import 'ai_limit_dialog.dart';

class AutoCompletionBlockKeys {
  const AutoCompletionBlockKeys._();

  static const String type = 'auto_completion';
  static const String prompt = 'prompt';
  static const String startSelection = 'start_selection';
  static const String generationCount = 'generation_count';
}

Node autoCompletionNode({
  String prompt = '',
  required Selection start,
}) {
  return Node(
    type: AutoCompletionBlockKeys.type,
    attributes: {
      AutoCompletionBlockKeys.prompt: prompt,
      AutoCompletionBlockKeys.startSelection: start.toJson(),
      AutoCompletionBlockKeys.generationCount: 0,
    },
  );
}

SelectionMenuItem autoGeneratorMenuItem = SelectionMenuItem.node(
  getName: LocaleKeys.document_plugins_autoGeneratorMenuItemName.tr,
  iconBuilder: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.menu_item_ai_writer_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['ai', 'openai', 'writer', 'ai writer', 'autogenerator'],
  nodeBuilder: (editorState, _) {
    final node = autoCompletionNode(start: editorState.selection!);
    return node;
  },
  replace: (_, node) => false,
);

class AutoCompletionBlockComponentBuilder extends BlockComponentBuilder {
  AutoCompletionBlockComponentBuilder();

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return AutoCompletionBlockComponent(
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
  bool validate(Node node) {
    return node.children.isEmpty &&
        node.attributes[AutoCompletionBlockKeys.prompt] is String &&
        node.attributes[AutoCompletionBlockKeys.startSelection] is Map;
  }
}

class AutoCompletionBlockComponent extends BlockComponentStatefulWidget {
  const AutoCompletionBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<AutoCompletionBlockComponent> createState() =>
      _AutoCompletionBlockComponentState();
}

class _AutoCompletionBlockComponentState
    extends State<AutoCompletionBlockComponent> {
  final controller = TextEditingController();
  final textFieldFocusNode = FocusNode();

  late final editorState = context.read<EditorState>();
  late final SelectionGestureInterceptor interceptor;

  String get prompt => widget.node.attributes[AutoCompletionBlockKeys.prompt];
  int get generationCount =>
      widget.node.attributes[AutoCompletionBlockKeys.generationCount] ?? 0;
  Selection? get startSelection {
    final selection =
        widget.node.attributes[AutoCompletionBlockKeys.startSelection];
    if (selection != null) {
      return Selection.fromJson(selection);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    _subscribeSelectionGesture();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      editorState.selection = null;
      textFieldFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _onExit();
    _unsubscribeSelectionGesture();
    controller.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMobile) {
      return const SizedBox.shrink();
    }

    final child = Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AutoCompletionHeader(),
            const Space(0, 10),
            if (prompt.isEmpty && generationCount < 1) ...[
              _buildInputWidget(context),
              const Space(0, 10),
              AutoCompletionInputFooter(
                onGenerate: _onGenerate,
                onExit: _onExit,
              ),
            ] else ...[
              AutoCompletionFooter(
                onKeep: _onExit,
                onRewrite: _onRewrite,
                onDiscard: _onDiscard,
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: child,
    );
  }

  Widget _buildInputWidget(BuildContext context) {
    return FlowyTextField(
      hintText: LocaleKeys.document_plugins_autoGeneratorHintText.tr(),
      controller: controller,
      maxLines: 5,
      focusNode: textFieldFocusNode,
      autoFocus: false,
      hintTextConstraints: const BoxConstraints(),
    );
  }

  Future<void> _onExit() async {
    final transaction = editorState.transaction..deleteNode(widget.node);
    await editorState.apply(
      transaction,
      options: const ApplyOptions(recordUndo: false),
      withUpdateSelection: false,
    );
  }

  Future<void> _onGenerate() async {
    await _updateEditingText();

    final userProfile = await UserBackendService.getCurrentUserProfile()
        .then((value) => value.toNullable());
    if (userProfile == null) {
      if (mounted) {
        showSnackBarMessage(
          context,
          LocaleKeys.document_plugins_autoGeneratorCantGetOpenAIKey.tr(),
          showCancel: true,
        );
      }
      return;
    }

    final textRobot = TextRobot(editorState: editorState);
    BarrierDialog? barrierDialog;
    final aiRepository = AppFlowyAIService();
    await aiRepository.streamCompletion(
      text: controller.text,
      completionType: CompletionTypePB.ContinueWriting,
      onStart: () async {
        if (mounted) {
          barrierDialog = BarrierDialog(context);
          barrierDialog?.show();
          await _makeSurePreviousNodeIsEmptyParagraphNode();
        }
      },
      onProcess: (text) async {
        await textRobot.autoInsertText(
          text,
          delay: Duration.zero,
        );
      },
      onEnd: () async {
        barrierDialog?.dismiss();
      },
      onError: (error) async {
        barrierDialog?.dismiss();
        if (mounted) {
          if (error.isLimitExceeded) {
            showAILimitDialog(context, error.message);
            await _onDiscard();
          } else {
            showSnackBarMessage(
              context,
              error.message,
              showCancel: true,
            );
          }
        }
      },
    );
    await _updateGenerationCount();
  }

  Future<void> _onDiscard() async {
    final selection = startSelection;
    if (selection != null) {
      final start = selection.start.path;
      final end = widget.node.previous?.path;
      if (end != null) {
        final transaction = editorState.transaction;
        transaction.deleteNodesAtPath(
          start,
          end.last - start.last + 1,
        );
        await editorState.apply(transaction);
        await _makeSurePreviousNodeIsEmptyParagraphNode();
      }
    }
    return _onExit();
  }

  Future<void> _onRewrite() async {
    final previousOutput = _getPreviousOutput();
    if (previousOutput == null) {
      return;
    }

    // clear previous response
    final selection = startSelection;
    if (selection != null) {
      final start = selection.start.path;
      final end = widget.node.previous?.path;
      if (end != null) {
        final transaction = editorState.transaction;
        transaction.deleteNodesAtPath(
          start,
          end.last - start.last + 1,
        );
        await editorState.apply(transaction);
      }
    }
    // generate new response
    final userProfile = await UserBackendService.getCurrentUserProfile()
        .then((value) => value.toNullable());
    if (userProfile == null) {
      if (mounted) {
        showSnackBarMessage(
          context,
          LocaleKeys.document_plugins_autoGeneratorCantGetOpenAIKey.tr(),
          showCancel: true,
        );
      }
      return;
    }
    final textRobot = TextRobot(editorState: editorState);
    final aiService = AppFlowyAIService();
    await aiService.streamCompletion(
      text: _rewritePrompt(previousOutput),
      completionType: CompletionTypePB.ContinueWriting,
      onStart: () async {
        await _makeSurePreviousNodeIsEmptyParagraphNode();
      },
      onProcess: (text) async {
        await textRobot.autoInsertText(
          text,
          delay: Duration.zero,
        );
      },
      onEnd: () async {},
      onError: (error) async {
        if (mounted) {
          if (error.isLimitExceeded) {
            showAILimitDialog(context, error.message);
          } else {
            showSnackBarMessage(
              context,
              error.message,
              showCancel: true,
            );
          }
        }
      },
    );
    await _updateGenerationCount();
  }

  String? _getPreviousOutput() {
    final startSelection = this.startSelection;
    if (startSelection != null) {
      final end = widget.node.previous?.path;

      if (end != null) {
        final result = editorState
            .getNodesInSelection(
          startSelection.copyWith(end: Position(path: end)),
        )
            .fold(
          '',
          (previousValue, element) {
            final delta = element.delta;
            if (delta != null) {
              return "$previousValue\n${delta.toPlainText()}";
            } else {
              return previousValue;
            }
          },
        );
        return result.trim();
      }
    }
    return null;
  }

  Future<void> _updateEditingText() async {
    final transaction = editorState.transaction;
    transaction.updateNode(
      widget.node,
      {
        AutoCompletionBlockKeys.prompt: controller.text,
      },
    );
    await editorState.apply(transaction);
  }

  Future<void> _updateGenerationCount() async {
    final transaction = editorState.transaction;
    transaction.updateNode(
      widget.node,
      {
        AutoCompletionBlockKeys.generationCount: generationCount + 1,
      },
    );
    await editorState.apply(transaction);
  }

  String _rewritePrompt(String previousOutput) {
    return 'I am not satisfied with your previous response ($previousOutput) to the query ($prompt). Please provide an alternative response.';
  }

  Future<void> _makeSurePreviousNodeIsEmptyParagraphNode() async {
    // make sure the previous node is a empty paragraph node without any styles.
    final transaction = editorState.transaction;
    final previous = widget.node.previous;
    final Selection selection;
    if (previous == null ||
        previous.type != ParagraphBlockKeys.type ||
        (previous.delta?.toPlainText().isNotEmpty ?? false)) {
      selection = Selection.single(
        path: widget.node.path,
        startOffset: 0,
      );
      transaction.insertNode(
        widget.node.path,
        paragraphNode(),
      );
    } else {
      selection = Selection.single(
        path: previous.path,
        startOffset: 0,
      );
    }
    transaction.updateNode(widget.node, {
      AutoCompletionBlockKeys.startSelection: selection.toJson(),
    });
    transaction.afterSelection = selection;
    await editorState.apply(transaction);
  }

  void _subscribeSelectionGesture() {
    interceptor = SelectionGestureInterceptor(
      key: AutoCompletionBlockKeys.type,
      canTap: (details) {
        if (!context.isOffsetInside(details.globalPosition)) {
          if (prompt.isNotEmpty || controller.text.isNotEmpty) {
            // show dialog
            showDialog(
              context: context,
              builder: (_) => DiscardDialog(
                onConfirm: _onDiscard,
                onCancel: () {},
              ),
            );
          } else if (controller.text.isEmpty) {
            _onExit();
          }
        }
        editorState.service.keyboardService?.disable();
        return false;
      },
    );
    editorState.service.selectionService.registerGestureInterceptor(
      interceptor,
    );
  }

  void _unsubscribeSelectionGesture() {
    editorState.service.selectionService.unregisterGestureInterceptor(
      AutoCompletionBlockKeys.type,
    );
  }
}

class AutoCompletionHeader extends StatelessWidget {
  const AutoCompletionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyText.medium(
      LocaleKeys.document_plugins_autoGeneratorTitleName.tr(),
      fontSize: 14,
    );
  }
}

class AutoCompletionInputFooter extends StatelessWidget {
  const AutoCompletionInputFooter({
    super.key,
    required this.onGenerate,
    required this.onExit,
  });

  final VoidCallback onGenerate;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryRoundedButton(
          text: LocaleKeys.button_generate.tr(),
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 10.0,
          ),
          radius: 8.0,
          onTap: onGenerate,
        ),
        const Space(10, 0),
        OutlinedRoundedButton(
          text: LocaleKeys.button_cancel.tr(),
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 10.0,
          ),
          onTap: onExit,
        ),
        Flexible(
          child: Container(
            alignment: Alignment.centerRight,
            child: FlowyText.regular(
              LocaleKeys.document_plugins_warning.tr(),
              color: Theme.of(context).hintColor,
              overflow: TextOverflow.ellipsis,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class AutoCompletionFooter extends StatelessWidget {
  const AutoCompletionFooter({
    super.key,
    required this.onKeep,
    required this.onRewrite,
    required this.onDiscard,
  });

  final VoidCallback onKeep;
  final VoidCallback onRewrite;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PrimaryRoundedButton(
          text: LocaleKeys.button_keep.tr(),
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 9.0,
          ),
          onTap: onKeep,
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.document_plugins_autoGeneratorRewrite.tr(),
          onTap: onRewrite,
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.button_discard.tr(),
          onTap: onDiscard,
        ),
      ],
    );
  }
}

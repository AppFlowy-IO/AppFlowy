import 'package:appflowy/plugins/document/presentation/editor_plugins/base/build_context_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/text_robot.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/openai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/util/learn_more_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/discard_dialog.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

class AutoCompletionBlockKeys {
  const AutoCompletionBlockKeys._();

  static const String type = 'auto_completion';
  static const String prompt = 'prompt';
  static const String startSelection = 'start_selection';
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
    },
  );
}

SelectionMenuItem autoGeneratorMenuItem = SelectionMenuItem.node(
  name: LocaleKeys.document_plugins_autoGeneratorMenuItemName.tr(),
  iconData: Icons.generating_tokens,
  keywords: ['ai', 'openai' 'writer', 'autogenerator'],
  nodeBuilder: (editorState) {
    final node = autoCompletionNode(start: editorState.selection!);
    return node;
  },
  replace: (_, node) => false,
);

class AutoCompletionBlockComponentBuilder extends BlockComponentBuilder {
  const AutoCompletionBlockComponentBuilder();

  @override
  Widget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return AutoCompletionBlockComponent(
      key: node.key,
      node: node,
    );
  }

  @override
  bool validate(Node node) {
    return node.children.isEmpty &&
        node.attributes[AutoCompletionBlockKeys.prompt] is String &&
        node.attributes[AutoCompletionBlockKeys.startSelection] is Map;
  }
}

class AutoCompletionBlockComponent extends StatefulWidget {
  const AutoCompletionBlockComponent({
    super.key,
    required this.node,
  });

  final Node node;

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
    _unsubscribeSelectionGesture();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AutoCompletionHeader(),
            const Space(0, 10),
            if (prompt.isEmpty) ...[
              _buildInputWidget(context),
              const Space(0, 10),
              AutoCompletionInputFooter(
                onGenerate: _onGenerate,
                onExit: _onExit,
              ),
            ] else ...[
              AutoCompletionFooter(
                onKeep: _onExit,
                onDiscard: _onDiscard,
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputWidget(BuildContext context) {
    return FlowyTextField(
      hintText: LocaleKeys.document_plugins_autoGeneratorHintText.tr(),
      controller: controller,
      maxLines: 3,
      focusNode: textFieldFocusNode,
      autoFocus: false,
    );
  }

  Future<void> _onExit() async {
    final transaction = editorState.transaction..deleteNode(widget.node);
    await editorState.apply(
      transaction,
      options: const ApplyOptions(
        // disable undo/redo
        recordRedo: false,
        recordUndo: false,
      ),
    );
  }

  Future<void> _onGenerate() async {
    final loading = Loading(context);
    loading.start();

    await _updateEditingText();

    final userProfile = await UserBackendService.getCurrentUserProfile()
        .then((value) => value.toOption().toNullable());
    if (userProfile == null) {
      loading.stop();
      await _showError(
        LocaleKeys.document_plugins_autoGeneratorCantGetOpenAIKey.tr(),
      );
      return;
    }

    final textRobot = TextRobot(editorState: editorState);
    BarrierDialog? barrierDialog;
    final openAIRepository = HttpOpenAIRepository(
      client: http.Client(),
      apiKey: userProfile.openaiKey,
    );
    await openAIRepository.getStreamedCompletions(
      prompt: controller.text,
      onStart: () async {
        loading.stop();
        barrierDialog = BarrierDialog(context);
        barrierDialog?.show();
        await _makeSurePreviousNodeIsEmptyParagraphNode();
      },
      onProcess: (response) async {
        if (response.choices.isNotEmpty) {
          final text = response.choices.first.text;
          await textRobot.autoInsertText(
            text,
            inputType: TextRobotInputType.word,
            delay: Duration.zero,
          );
        }
      },
      onEnd: () async {
        await barrierDialog?.dismiss();
      },
      onError: (error) async {
        loading.stop();
        await _showError(error.message);
      },
    );
  }

  Future<void> _onDiscard() async {
    final selection =
        widget.node.attributes[AutoCompletionBlockKeys.startSelection];
    if (selection != null) {
      final start = Selection.fromJson(selection).start.path;
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
    _onExit();
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

  Future<void> _makeSurePreviousNodeIsEmptyParagraphNode() async {
    // make sure the previous node is a empty paragraph node without any styles.
    final transaction = editorState.transaction;
    final previous = widget.node.previous;
    final Selection selection;
    if (previous == null ||
        previous.type != 'paragraph' ||
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

  Future<void> _showError(String message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        action: SnackBarAction(
          label: LocaleKeys.button_Cancel.tr(),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        content: FlowyText(message),
      ),
    );
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
              builder: (context) {
                return DiscardDialog(
                  onConfirm: () => _onDiscard(),
                  onCancel: () {},
                );
              },
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
  const AutoCompletionHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FlowyText.medium(
          LocaleKeys.document_plugins_autoGeneratorTitleName.tr(),
          fontSize: 14,
        ),
        const Spacer(),
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowyText.regular(
            LocaleKeys.document_plugins_autoGeneratorLearnMore.tr(),
          ),
          onTap: () async {
            await openLearnMorePage();
          },
        )
      ],
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
      children: [
        PrimaryTextButton(
          LocaleKeys.button_generate.tr(),
          onPressed: onGenerate,
        ),
        const Space(10, 0),
        SecondaryTextButton(
          LocaleKeys.button_Cancel.tr(),
          onPressed: onExit,
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            child: FlowyText.regular(
              LocaleKeys.document_plugins_warning.tr(),
              color: Theme.of(context).hintColor,
              overflow: TextOverflow.ellipsis,
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
    required this.onDiscard,
  });

  final VoidCallback onKeep;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PrimaryTextButton(
          LocaleKeys.button_keep.tr(),
          onPressed: onKeep,
        ),
        const Space(10, 0),
        SecondaryTextButton(
          LocaleKeys.button_discard.tr(),
          onPressed: onDiscard,
        ),
      ],
    );
  }
}

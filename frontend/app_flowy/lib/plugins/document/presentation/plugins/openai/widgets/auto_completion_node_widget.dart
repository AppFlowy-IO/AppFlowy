import 'package:app_flowy/plugins/document/presentation/plugins/openai/service/openai_client.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/openai/widgets/loading.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import '../util/editor_extension.dart';

const String kAutoCompletionInputType = 'auto_completion_input';
const String kAutoCompletionInputString = 'auto_completion_input_string';
const String kAutoCompletionInputStartSelection =
    'auto_completion_input_start_selection';

class AutoCompletionInputBuilder extends NodeWidgetBuilder<Node> {
  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.attributes[kAutoCompletionInputString] is String;
      };

  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _AutoCompletionInput(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }
}

class _AutoCompletionInput extends StatefulWidget {
  final Node node;

  final EditorState editorState;
  const _AutoCompletionInput({
    Key? key,
    required this.node,
    required this.editorState,
  });

  @override
  State<_AutoCompletionInput> createState() => _AutoCompletionInputState();
}

class _AutoCompletionInputState extends State<_AutoCompletionInput> {
  String get text => widget.node.attributes[kAutoCompletionInputString];

  final controller = TextEditingController();
  final focusNode = FocusNode();
  final textFieldFocusNode = FocusNode();

  late BuildContext loadingContext;

  @override
  void initState() {
    super.initState();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        widget.editorState.service.selectionService.clearSelection();
      } else {
        widget.editorState.service.keyboardService?.enable();
      }
    });
    textFieldFocusNode.requestFocus();
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FlowyContainer(
        Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: _buildAutoGeneratorPanel(context),
      ),
    );
  }

  Widget _buildAutoGeneratorPanel(BuildContext context) {
    if (text.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderWidget(context),
          const Space(0, 10),
          _buildInputWidget(context),
          const Space(0, 10),
          _buildInputFooterWidget(context),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderWidget(context),
          const Space(0, 10),
          _buildFooterWidget(context),
        ],
      );
    }
  }

  Widget _buildHeaderWidget(BuildContext context) {
    return Row(
      children: [
        FlowyText.regular(
          LocaleKeys.document_plugins_autoGeneratorTitleName.tr(),
        ),
        const Spacer(),
        FlowyText.regular(
          LocaleKeys.document_plugins_autoGeneratorLearnMore.tr(),
        ),
      ],
    );
  }

  Widget _buildInputWidget(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (RawKeyEvent event) async {
        if (event is! RawKeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (controller.text.isNotEmpty) {
            await _onGenerate();
          }
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _onExit();
        }
      },
      child: FlowyTextField(
        hintText: LocaleKeys.document_plugins_autoGeneratorHintText.tr(),
        controller: controller,
        maxLines: 3,
        focusNode: textFieldFocusNode,
        autoFocus: false,
      ),
    );
  }

  Widget _buildInputFooterWidget(BuildContext context) {
    return Row(
      children: [
        // FIXME: l10n
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: '${LocaleKeys.button_generate.tr()}  ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextSpan(
                text: '↵',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ), // FIXME: color
              ),
            ],
          ),
          onPressed: () => _onGenerate(),
        ),
        const Space(10, 0),
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: '${LocaleKeys.button_Cancel.tr()}  ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextSpan(
                text: LocaleKeys.button_esc.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ), // FIXME: color
              ),
            ],
          ),
          onPressed: () => _onExit(),
        ),
      ],
    );
  }

  Widget _buildFooterWidget(BuildContext context) {
    return Row(
      children: [
        // FIXME: l10n
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: '${LocaleKeys.button_keep.tr()}  ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          onPressed: () => _onExit(),
        ),
        const Space(10, 0),
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: '${LocaleKeys.button_discard.tr()}  ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          onPressed: () => _onDiscard(),
        ),
      ],
    );
  }

  void _onExit() {
    final transaction = widget.editorState.transaction;
    transaction.deleteNode(widget.node);
    widget.editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordRedo: false,
        recordUndo: false,
      ),
    );
  }

  Future<void> _onGenerate() async {
    // fetch the result and insert it
    textFieldFocusNode.unfocus();
    final loading = Loading(context);
    loading.start();
    await _updateEditingText();
    final result = await UserService.getCurrentUserProfile();
    result.fold((userProfile) {
      HttpOpenAIRepository(
        client: http.Client(),
        apiKey: userProfile.openaiKey,
      ).getCompletions(prompt: controller.text).then((result) {
        result.fold((error) {
          // Error.
          assert(false, 'Error: $error');
        }, (textCompletion) async {
          loading.stop();
          await _makeSurePreviousNodeIsEmptyTextNode();
          await widget.editorState.autoInsertText(
            textCompletion.choices.first.text,
          );
          focusNode.requestFocus();
        });
      });
    }, (error) {
      // TODO: show a toast.
      assert(false, 'User profile not found.');
    });
  }

  Future<void> _onDiscard() async {
    final json = widget.node.attributes[kAutoCompletionInputStartSelection];
    if (json != null) {
      final start = Selection.fromJson(json).start.path;
      final end = widget.node.previous?.path;
      if (end != null) {
        final transaction = widget.editorState.transaction;
        transaction.deleteNodesAtPath(
          start,
          end.last - start.last,
        );
        await widget.editorState.apply(transaction);
      }
    }
    _onExit();
  }

  Future<void> _updateEditingText() async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(
      widget.node,
      {
        kAutoCompletionInputString: controller.text,
      },
    );
    await widget.editorState.apply(transaction);
  }

  Future<void> _makeSurePreviousNodeIsEmptyTextNode() async {
    // make sure the previous node is a empty text node.
    final transaction = widget.editorState.transaction;
    final Selection selection;
    if (widget.node.previous is! TextNode ||
        (widget.node.previous as TextNode).toPlainText().isNotEmpty) {
      transaction.insertNode(
        widget.node.path,
        TextNode.empty(),
      );
      selection = Selection.single(
        path: widget.node.path,
        startOffset: 0,
      );
      transaction.afterSelection = selection;
    } else {
      selection = Selection.single(
        path: widget.node.path.previous,
        startOffset: 0,
      );
      transaction.afterSelection = selection;
    }
    transaction.updateNode(widget.node, {
      kAutoCompletionInputStartSelection: selection.toJson(),
    });
    await widget.editorState.apply(transaction);
  }
}

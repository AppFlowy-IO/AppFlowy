import 'package:app_flowy/plugins/document/presentation/plugins/openai/service/openai_client.dart';
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

import '../util/editor_extension.dart';

const String kAutoCompletionInputString = 'auto_completion_input_string';
const String kAutoCompletionInputType = 'auto_completion_input';

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
  late TextEditingController controller = TextEditingController(
    text: widget.node.attributes[kAutoCompletionInputString],
  );

  final focusNode = FocusNode();
  final textFieldFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FlowyContainer(
        Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Title
            Row(
              children: const [
                FlowyText.regular('Open AI: Auto Generater'),
                Spacer(),
                FlowyText.regular('Learn more'),
              ],
            ),
            // Space
            const Space(0, 10),
            // Input
            RawKeyboardListener(
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
                hintText: 'Tell us what you want to generate by OpenAI...',
                controller: controller,
                maxLines: 3,
                focusNode: textFieldFocusNode,
              ),
            ),
            // Space
            const Space(0, 10),
            // Actions
            Row(
              children: [
                // FIXME: l10n
                FlowyRichTextButton(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Generate  ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextSpan(
                        text: '↵',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey), // FIXME: color
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
                        text: 'Cancel  ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextSpan(
                        text: 'ESC',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey), // FIXME: color
                      ),
                    ],
                  ),
                  onPressed: () => _onExit(),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

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
  }

  Future<void> _makeSurePreviousNodeIsTextNode() async {
    // make sure the previous node is a text node.
    final transaction = widget.editorState.transaction;
    if (widget.node.previous is! TextNode) {
      transaction.insertNode(
        widget.node.path,
        TextNode.empty(),
      );
      transaction.afterSelection = Selection.single(
        path: widget.node.path,
        startOffset: 0,
      );
    } else {
      final previous = widget.node.previous as TextNode;
      transaction.afterSelection = Selection.single(
        path: previous.path,
        startOffset: previous.toPlainText().length,
      );
    }
    await widget.editorState.apply(transaction);
  }

  void _onExit() {
    final transaction = widget.editorState.transaction;
    transaction.deleteNode(widget.node);
    widget.editorState.apply(transaction);
  }

  Future<void> _onGenerate() async {
    // fetch the result and insert it
    textFieldFocusNode.unfocus();
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
          await _makeSurePreviousNodeIsTextNode();
          await widget.editorState.autoInsertText(
            textCompletion.choices.first.text,
          );
        });
      });
    }, (error) {
      // TODO: show a toast.
      assert(false, 'User profile not found.');
    });
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
}

import 'package:app_flowy/plugins/document/presentation/plugins/openai/service/error.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/openai/service/openai_client.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/openai/service/text_edit.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/openai/widgets/smart_edit_action.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart' as dartz;
import 'package:app_flowy/util/either_extension.dart';

const String kSmartEditType = 'smart_edit_input';
const String kSmartEditInstructionType = 'smart_edit_instruction';
const String kSmartEditInputType = 'smart_edit_input';

class SmartEditInputBuilder extends NodeWidgetBuilder<Node> {
  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return SmartEditAction.values.map((e) => e.toInstruction).contains(
                  node.attributes[kSmartEditInstructionType],
                ) &&
            node.attributes[kSmartEditInputType] is String;
      };

  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _SmartEditInput(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }
}

class _SmartEditInput extends StatefulWidget {
  final Node node;

  final EditorState editorState;
  const _SmartEditInput({
    Key? key,
    required this.node,
    required this.editorState,
  });

  @override
  State<_SmartEditInput> createState() => _SmartEditInputState();
}

class _SmartEditInputState extends State<_SmartEditInput> {
  String get instruction => widget.node.attributes[kSmartEditInstructionType];
  String get input => widget.node.attributes[kSmartEditInputType];

  final focusNode = FocusNode();
  final textFieldFocusNode = FocusNode();
  final controller = TextEditingController();
  dartz.Either<OpenAIError, TextEditResponse>? result;
  bool loading = true;

  @override
  void initState() {
    super.initState();

    widget.editorState.service.keyboardService?.disable(showCursor: true);
    focusNode.requestFocus();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        widget.editorState.service.keyboardService?.enable();
      }
    });
    _requestEdits().then(
      (value) => setState(() {
        result = value;
        loading = false;
      }),
    );
  }

  @override
  void dispose() {
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
        child: _buildSmartEditPanel(context),
      ),
    );
  }

  Widget _buildSmartEditPanel(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (RawKeyEvent event) async {
        if (event is! RawKeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (controller.text.isNotEmpty) {
            textFieldFocusNode.unfocus();
          }
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          await _onExit();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderWidget(context),
          const Space(0, 10),
          _buildResultWidget(context),
          const Space(0, 10),
          _buildInputFooterWidget(context),
        ],
      ),
    );
  }

  Widget _buildHeaderWidget(BuildContext context) {
    return Row(
      children: [
        FlowyText.medium(
          LocaleKeys.document_plugins_smartEditTitleName.tr(),
          fontSize: 14,
        ),
        const Spacer(),
        FlowyText.regular(
          LocaleKeys.document_plugins_autoGeneratorLearnMore.tr(),
        ),
      ],
    );
  }

  Widget _buildResultWidget(BuildContext context) {
    final loading = SizedBox.fromSize(
      size: const Size.square(14),
      child: const CircularProgressIndicator(),
    );
    if (result == null) {
      return loading;
    }
    return result!.fold((error) {
      return Flexible(
        child: Text(
          error.message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ),
        ),
      );
    }, (response) {
      return Flexible(
        child: Text(
          response.choices.map((e) => e.text).join('\n'),
        ),
      );
    });
  }

  Widget _buildInputFooterWidget(BuildContext context) {
    return Row(
      children: [
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: '${LocaleKeys.button_replace.tr()}  ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextSpan(
                text: '↵',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
          onPressed: () => _onReplace(),
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
                    ),
              ),
            ],
          ),
          onPressed: () async => await _onExit(),
        ),
      ],
    );
  }

  Future<void> _onReplace() async {
    final selection =
        widget.editorState.service.selectionService.currentSelection.value;
    final selectedNodes =
        widget.editorState.service.selectionService.currentSelectedNodes;
    if (selection == null || result == null || result!.isLeft()) {
      return;
    }
    final transaction = widget.editorState.transaction;
    transaction.insertNodes(
        widget.node.path,
        result!
            .asRight()
            .choices
            .first
            .text
            .split('\n')
            .map((e) => TextNode(delta: Delta()..insert(e.trim()))));
    transaction.deleteNodes(selectedNodes);
    transaction.deleteNode(widget.node);
    transaction.afterSelection = null;
    return widget.editorState.apply(transaction, withUpdateCursor: false);
  }

  Future<void> _onExit() async {
    final transaction = widget.editorState.transaction;
    transaction.deleteNode(widget.node);
    transaction.afterSelection = null;
    return widget.editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordRedo: false,
        recordUndo: false,
      ),
      withUpdateCursor: false,
    );
  }

  Future<dartz.Either<OpenAIError, TextEditResponse>> _requestEdits() async {
    final result = await UserService.getCurrentUserProfile();
    return result.fold((userProfile) async {
      final openAIRepository = HttpOpenAIRepository(
        client: http.Client(),
        apiKey: userProfile.openaiKey,
      );
      final edits = await openAIRepository.getEdits(
        input: input,
        instruction: instruction,
      );
      return edits.fold((error) async {
        return const dartz.Left(
          OpenAIError(message: 'Could not get edits'),
        );
      }, (textEdit) async {
        return dartz.Right(textEdit);
      });
    }, (error) async {
      // error
      return const dartz.Left(
        OpenAIError(message: 'Could not get user profile'),
      );
    });
  }
}

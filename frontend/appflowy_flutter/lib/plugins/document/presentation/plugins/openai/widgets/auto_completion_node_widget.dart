import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/plugins/openai/service/openai_client.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/util/learn_more_action.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/discard_dialog.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/loading.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:appflowy/generated/locale_keys.g.dart';
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
  final interceptor = SelectionInterceptor();

  @override
  void initState() {
    super.initState();

    textFieldFocusNode.addListener(_onFocusChanged);
    textFieldFocusNode.requestFocus();
    widget.editorState.service.selectionService.register(
      interceptor
        ..canTap = (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            if (!isTapDownDetailsInRenderBox(details, renderBox)) {
              if (text.isNotEmpty || controller.text.isNotEmpty) {
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
          }
          return false;
        },
    );
  }

  bool isTapDownDetailsInRenderBox(TapDownDetails details, RenderBox box) {
    var result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(details.globalPosition));
    return result.path.any((entry) => entry.target == box);
  }

  @override
  void dispose() {
    controller.dispose();
    textFieldFocusNode.removeListener(_onFocusChanged);
    widget.editorState.service.selectionService.currentSelection
        .removeListener(_onCancelWhenSelectionChanged);
    widget.editorState.service.selectionService.unRegister(interceptor);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        margin: const EdgeInsets.all(10),
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

  Widget _buildInputWidget(BuildContext context) {
    return FlowyTextField(
      hintText: LocaleKeys.document_plugins_autoGeneratorHintText.tr(),
      controller: controller,
      maxLines: 3,
      focusNode: textFieldFocusNode,
      autoFocus: false,
    );
  }

  Widget _buildInputFooterWidget(BuildContext context) {
    return Row(
      children: [
        PrimaryTextButton(
          LocaleKeys.button_generate.tr(),
          onPressed: () async => await _onGenerate(),
        ),
        const Space(10, 0),
        SecondaryTextButton(
          LocaleKeys.button_Cancel.tr(),
          onPressed: () async => await _onExit(),
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

  Widget _buildFooterWidget(BuildContext context) {
    return Row(
      children: [
        PrimaryTextButton(
          LocaleKeys.button_keep.tr(),
          onPressed: () => _onExit(),
        ),
        const Space(10, 0),
        SecondaryTextButton(
          LocaleKeys.button_discard.tr(),
          onPressed: () => _onDiscard(),
        ),
      ],
    );
  }

  Future<void> _onExit() async {
    final transaction = widget.editorState.transaction;
    transaction.deleteNode(widget.node);
    await widget.editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordRedo: false,
        recordUndo: false,
      ),
    );
  }

  Future<void> _onGenerate() async {
    final loading = Loading(context);
    loading.start();
    await _updateEditingText();
    final result = await UserBackendService.getCurrentUserProfile();

    result.fold((userProfile) async {
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
          await _makeSurePreviousNodeIsEmptyTextNode();
        },
        onProcess: (response) async {
          if (response.choices.isNotEmpty) {
            final text = response.choices.first.text;
            await widget.editorState.autoInsertText(
              text,
              inputType: TextRobotInputType.word,
              delay: Duration.zero,
            );
          }
        },
        onEnd: () async {
          await barrierDialog?.dismiss();
          widget.editorState.service.selectionService.currentSelection
              .addListener(_onCancelWhenSelectionChanged);
        },
        onError: (error) async {
          loading.stop();
          await _showError(error.message);
        },
      );
    }, (error) async {
      loading.stop();
      await _showError(
        LocaleKeys.document_plugins_autoGeneratorCantGetOpenAIKey.tr(),
      );
    });
  }

  Future<void> _onDiscard() async {
    final selection =
        widget.node.attributes[kAutoCompletionInputStartSelection];
    if (selection != null) {
      final start = Selection.fromJson(json.decode(selection)).start.path;
      final end = widget.node.previous?.path;
      if (end != null) {
        final transaction = widget.editorState.transaction;
        transaction.deleteNodesAtPath(
          start,
          end.last - start.last + 1,
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
    // make sure the previous node is a empty text node without any styles.
    final transaction = widget.editorState.transaction;
    final Selection selection;
    if (widget.node.previous is! TextNode ||
        (widget.node.previous as TextNode).toPlainText().isNotEmpty ||
        (widget.node.previous as TextNode).subtype != null) {
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
      kAutoCompletionInputStartSelection: jsonEncode(selection.toJson()),
    });
    await widget.editorState.apply(transaction);
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

  void _onFocusChanged() {
    if (textFieldFocusNode.hasFocus) {
      widget.editorState.service.keyboardService?.disable(
        disposition: UnfocusDisposition.previouslyFocusedChild,
      );
    } else {
      widget.editorState.service.keyboardService?.enable();
    }
  }

  void _onCancelWhenSelectionChanged() {}
}

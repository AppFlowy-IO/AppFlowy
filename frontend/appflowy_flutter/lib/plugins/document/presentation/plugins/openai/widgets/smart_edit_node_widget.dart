import 'dart:async';

import 'package:appflowy/plugins/document/presentation/plugins/openai/service/openai_client.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/util/learn_more_action.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/discard_dialog.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;

const String kSmartEditType = 'smart_edit_input';
const String kSmartEditInstructionType = 'smart_edit_instruction';
const String kSmartEditInputType = 'smart_edit_input';

class SmartEditInputBuilder extends NodeWidgetBuilder<Node> {
  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return SmartEditAction.values
                .map((e) => e.index)
                .contains(node.attributes[kSmartEditInstructionType]) &&
            node.attributes[kSmartEditInputType] is String;
      };

  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _HoverSmartInput(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }
}

class _HoverSmartInput extends StatefulWidget {
  const _HoverSmartInput({
    required super.key,
    required this.node,
    required this.editorState,
  });

  final Node node;
  final EditorState editorState;

  @override
  State<_HoverSmartInput> createState() => _HoverSmartInputState();
}

class _HoverSmartInputState extends State<_HoverSmartInput> {
  final popoverController = PopoverController();
  final key = GlobalKey(debugLabel: 'smart_edit_input');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      popoverController.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = _maxWidth();

    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      margin: EdgeInsets.zero,
      constraints: BoxConstraints(maxWidth: width),
      decoration: FlowyDecoration.decoration(
        Colors.transparent,
        Colors.transparent,
      ),
      child: const SizedBox(
        width: double.infinity,
      ),
      canClose: () async {
        final completer = Completer<bool>();
        final state = key.currentState as _SmartEditInputState;
        if (state.result.isEmpty) {
          completer.complete(true);
        } else {
          showDialog(
            context: context,
            builder: (context) {
              return DiscardDialog(
                onConfirm: () => completer.complete(true),
                onCancel: () => completer.complete(false),
              );
            },
          );
        }
        return completer.future;
      },
      popupBuilder: (BuildContext popoverContext) {
        return _SmartEditInput(
          key: key,
          node: widget.node,
          editorState: widget.editorState,
        );
      },
    );
  }

  double _maxWidth() {
    var width = double.infinity;
    final editorSize = widget.editorState.renderBox?.size;
    final padding = widget.editorState.editorStyle.padding;
    if (editorSize != null && padding != null) {
      width = editorSize.width - padding.left - padding.right;
    }
    return width;
  }
}

class _SmartEditInput extends StatefulWidget {
  const _SmartEditInput({
    required super.key,
    required this.node,
    required this.editorState,
  });

  final Node node;
  final EditorState editorState;

  @override
  State<_SmartEditInput> createState() => _SmartEditInputState();
}

class _SmartEditInputState extends State<_SmartEditInput> {
  SmartEditAction get action =>
      SmartEditAction.from(widget.node.attributes[kSmartEditInstructionType]);
  String get input => widget.node.attributes[kSmartEditInputType];

  final focusNode = FocusNode();
  final client = http.Client();
  bool loading = true;
  String result = '';

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
    _requestCompletions();
  }

  @override
  void dispose() {
    client.close();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderWidget(context),
        const Space(0, 10),
        _buildResultWidget(context),
        const Space(0, 10),
        _buildInputFooterWidget(context),
      ],
    );
  }

  Widget _buildHeaderWidget(BuildContext context) {
    return Row(
      children: [
        FlowyText.medium(
          '${LocaleKeys.document_plugins_openAI.tr()}: ${action.name}',
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

  Widget _buildResultWidget(BuildContext context) {
    final loading = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox.fromSize(
        size: const Size.square(14),
        child: const CircularProgressIndicator(),
      ),
    );
    if (result.isEmpty) {
      return loading;
    }
    return Flexible(
      child: Text(
        result,
      ),
    );
  }

  Widget _buildInputFooterWidget(BuildContext context) {
    return Row(
      children: [
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: LocaleKeys.button_replace.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          onPressed: () async {
            await _onReplace();
            _onExit();
          },
        ),
        const Space(10, 0),
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: LocaleKeys.button_insertBelow.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          onPressed: () async {
            await _onInsertBelow();
            _onExit();
          },
        ),
        const Space(10, 0),
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: LocaleKeys.button_Cancel.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          onPressed: () async => await _onExit(),
        ),
        const Spacer(),
        FlowyText.regular(
          LocaleKeys.document_plugins_warning.tr(),
          color: Theme.of(context).hintColor,
        ),
      ],
    );
  }

  Future<void> _onReplace() async {
    final selection = widget.editorState.service.selectionService
        .currentSelection.value?.normalized;
    final selectedNodes = widget
        .editorState.service.selectionService.currentSelectedNodes.normalized
        .whereType<TextNode>();
    if (selection == null || result.isEmpty) {
      return;
    }

    final texts = result.split('\n')..removeWhere((element) => element.isEmpty);
    final transaction = widget.editorState.transaction;
    transaction.replaceTexts(
      selectedNodes.toList(growable: false),
      selection,
      texts,
    );
    return widget.editorState.apply(transaction);
  }

  Future<void> _onInsertBelow() async {
    final selection = widget.editorState.service.selectionService
        .currentSelection.value?.normalized;
    if (selection == null || result.isEmpty) {
      return;
    }
    final texts = result.split('\n')..removeWhere((element) => element.isEmpty);
    final transaction = widget.editorState.transaction;
    transaction.insertNodes(
      selection.normalized.end.path.next,
      texts.map(
        (e) => TextNode(
          delta: Delta()..insert(e),
        ),
      ),
    );
    return widget.editorState.apply(transaction);
  }

  Future<void> _onExit() async {
    final transaction = widget.editorState.transaction;
    transaction.deleteNode(widget.node);
    return widget.editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordRedo: false,
        recordUndo: false,
      ),
    );
  }

  Future<void> _requestCompletions() async {
    final result = await UserBackendService.getCurrentUserProfile();
    return result.fold((l) async {
      final openAIRepository = HttpOpenAIRepository(
        client: client,
        apiKey: l.openaiKey,
      );

      var lines = input.split('\n\n');
      if (action == SmartEditAction.summarize) {
        lines = [lines.join('\n')];
      }
      for (var i = 0; i < lines.length; i++) {
        final element = lines[i];
        await openAIRepository.getStreamedCompletions(
          useAction: true,
          prompt: action.prompt(element),
          onStart: () async {
            setState(() {
              loading = false;
            });
          },
          onProcess: (response) async {
            setState(() {
              this.result += response.choices.first.text;
            });
          },
          onEnd: () async {
            setState(() {
              if (i != lines.length - 1) {
                this.result += '\n';
              }
            });
          },
          onError: (error) async {
            await _showError(error.message);
            await _onExit();
          },
        );
      }
    }, (r) async {
      await _showError(r.msg);
      await _onExit();
    });
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
}

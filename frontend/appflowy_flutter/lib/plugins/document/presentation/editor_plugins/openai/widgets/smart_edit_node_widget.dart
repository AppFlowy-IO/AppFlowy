import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/discard_dialog.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/ai_service.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'ai_limit_dialog.dart';

class SmartEditBlockKeys {
  const SmartEditBlockKeys._();

  static const type = 'smart_edit';

  /// The instruction of the smart edit.
  ///
  /// It is a [SmartEditAction] value.
  static const action = 'action';

  /// The input of the smart edit.
  static const content = 'content';
}

Node smartEditNode({
  required SmartEditAction action,
  required String content,
}) {
  return Node(
    type: SmartEditBlockKeys.type,
    attributes: {
      SmartEditBlockKeys.action: action.index,
      SmartEditBlockKeys.content: content,
    },
  );
}

class SmartEditBlockComponentBuilder extends BlockComponentBuilder {
  SmartEditBlockComponentBuilder();

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return SmartEditBlockComponentWidget(
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
  bool validate(Node node) =>
      node.attributes[SmartEditBlockKeys.action] is int &&
      node.attributes[SmartEditBlockKeys.content] is String;
}

class SmartEditBlockComponentWidget extends BlockComponentStatefulWidget {
  const SmartEditBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<SmartEditBlockComponentWidget> createState() =>
      _SmartEditBlockComponentWidgetState();
}

class _SmartEditBlockComponentWidgetState
    extends State<SmartEditBlockComponentWidget> {
  final popoverController = PopoverController();
  final key = GlobalKey(debugLabel: 'smart_edit_input');

  late final editorState = context.read<EditorState>();

  @override
  void initState() {
    super.initState();

    // todo: don't use a popover to show the content of the smart edit.
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      popoverController.show();
    });
  }

  @override
  void reassemble() {
    super.reassemble();

    final transaction = editorState.transaction..deleteNode(widget.node);
    editorState.apply(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final width = _getEditorWidth();

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
        final state = key.currentState as _SmartEditInputWidgetState;
        if (state.result.isEmpty) {
          completer.complete(true);
        } else {
          await showDialog(
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
      onClose: () {
        final transaction = editorState.transaction..deleteNode(widget.node);
        editorState.apply(transaction);
      },
      popupBuilder: (BuildContext popoverContext) {
        return SmartEditInputWidget(
          key: key,
          node: widget.node,
          editorState: editorState,
        );
      },
    );
  }

  double _getEditorWidth() {
    var width = double.infinity;
    final editorSize = editorState.renderBox?.size;
    final padding = editorState.editorStyle.padding;
    if (editorSize != null) {
      width = editorSize.width - padding.left - padding.right;
    }
    return width;
  }
}

class SmartEditInputWidget extends StatefulWidget {
  const SmartEditInputWidget({
    required super.key,
    required this.node,
    required this.editorState,
  });

  final Node node;
  final EditorState editorState;

  @override
  State<SmartEditInputWidget> createState() => _SmartEditInputWidgetState();
}

class _SmartEditInputWidgetState extends State<SmartEditInputWidget> {
  final focusNode = FocusNode();
  final client = http.Client();

  SmartEditAction get action => SmartEditAction.from(
        widget.node.attributes[SmartEditBlockKeys.action],
      );
  String get content => widget.node.attributes[SmartEditBlockKeys.content];
  EditorState get editorState => widget.editorState;

  bool loading = true;
  String result = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      editorState.service.keyboardService?.disable();
      // editorState.selection = null;
    });

    focusNode.requestFocus();
    _requestCompletions();
  }

  @override
  void dispose() {
    client.close();
    focusNode.dispose();
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
        FlowyText.medium(
          action.name,
          fontSize: 14,
        ),
        // _buildHeaderWidget(context),
        const Space(0, 10),
        _buildResultWidget(context),
        const Space(0, 10),
        _buildInputFooterWidget(context),
      ],
    );
  }

  Widget _buildResultWidget(BuildContext context) {
    final loadingWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox.fromSize(
        size: const Size.square(14),
        child: const CircularProgressIndicator(),
      ),
    );
    if (result.isEmpty || loading) {
      return loadingWidget;
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
                text: LocaleKeys.document_plugins_autoGeneratorRewrite.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          onPressed: () => _requestCompletions(rewrite: true),
        ),
        const Space(10, 0),
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
            await _onExit();
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
            await _onExit();
          },
        ),
        const Space(10, 0),
        FlowyRichTextButton(
          TextSpan(
            children: [
              TextSpan(
                text: LocaleKeys.button_cancel.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          onPressed: () async => _onExit(),
        ),
        const Spacer(),
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

  Future<void> _onReplace() async {
    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return;
    }
    final nodes = editorState.getNodesInSelection(selection);
    if (nodes.isEmpty || !nodes.every((element) => element.delta != null)) {
      return;
    }
    final replaceTexts = result.split('\n')
      ..removeWhere((element) => element.isEmpty);
    final transaction = editorState.transaction;
    transaction.replaceTexts(
      nodes,
      selection,
      replaceTexts,
    );
    await editorState.apply(transaction);

    int endOffset = replaceTexts.last.length;
    if (replaceTexts.length == 1) {
      endOffset += selection.start.offset;
    }

    editorState.selection = Selection(
      start: selection.start,
      end: Position(
        path: [selection.start.path.first + replaceTexts.length - 1],
        offset: endOffset,
      ),
    );
  }

  Future<void> _onInsertBelow() async {
    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return;
    }
    final insertedText = result.split('\n')
      ..removeWhere((element) => element.isEmpty);
    final transaction = editorState.transaction;
    transaction.insertNodes(
      selection.end.path.next,
      insertedText.map(
        (e) => paragraphNode(
          text: e,
        ),
      ),
    );
    transaction.afterSelection = Selection(
      start: Position(path: selection.end.path.next),
      end: Position(
        path: [selection.end.path.next.first + insertedText.length],
      ),
    );
    await editorState.apply(transaction);
  }

  Future<void> _onExit() async {
    final transaction = editorState.transaction..deleteNode(widget.node);
    return editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordUndo: false,
      ),
    );
  }

  Future<void> _requestCompletions({bool rewrite = false}) async {
    if (rewrite) {
      setState(() {
        loading = true;
        result = "";
      });
    }
    final aiResitory = await getIt.getAsync<AIRepository>();
    await aiResitory.streamCompletion(
      text: content,
      completionType: completionTypeFromInt(action),
      onStart: () async {
        setState(() {
          loading = false;
        });
      },
      onProcess: (text) async {
        setState(() {
          result += text;
        });
      },
      onEnd: () async {
        setState(() {
          result += '\n';
        });
      },
      onError: (error) async {
        if (error.isLimitExceeded) {
          showAILimitDialog(context, error.message);
        } else {
          showSnackBarMessage(
            context,
            error.message,
            showCancel: true,
          );
        }
        await _onExit();
      },
    );
  }
}

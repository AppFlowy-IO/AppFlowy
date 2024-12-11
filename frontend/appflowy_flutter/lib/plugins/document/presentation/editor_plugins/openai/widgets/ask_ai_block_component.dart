import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/ai_limit_dialog.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/ask_ai_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/ask_ai_action_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/ask_ai_block_widgets.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

class AskAIBlockKeys {
  const AskAIBlockKeys._();

  static const type = 'ask_ai';

  /// The instruction of the smart edit.
  ///
  /// It is a [AskAIAction] value.
  static const action = 'action';

  /// The input of the smart edit.
  ///
  /// The content is a string that using '\n\n' as separator.
  static const content = 'content';
}

Node askAINode({
  required AskAIAction action,
  required String content,
}) {
  return Node(
    type: AskAIBlockKeys.type,
    attributes: {
      AskAIBlockKeys.action: action.index,
      AskAIBlockKeys.content: content,
    },
  );
}

class AskAIBlockComponentBuilder extends BlockComponentBuilder {
  AskAIBlockComponentBuilder();

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return AskAIBlockComponentWidget(
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
      node.attributes[AskAIBlockKeys.action] is int &&
      node.attributes[AskAIBlockKeys.content] is String;
}

class AskAIBlockComponentWidget extends BlockComponentStatefulWidget {
  const AskAIBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<AskAIBlockComponentWidget> createState() =>
      _AskAIBlockComponentWidgetState();
}

class _AskAIBlockComponentWidgetState extends State<AskAIBlockComponentWidget> {
  final popoverController = PopoverController();

  late final editorState = context.read<EditorState>();
  late final action =
      AskAIAction.values[widget.node.attributes[AskAIBlockKeys.action] as int];
  late AskAIActionBloc askAIBloc;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      popoverController.show();
    });

    askAIBloc = AskAIActionBloc(
      node: widget.node,
      editorState: editorState,
      action: action,
    )..add(AskAIEvent.initial(getIt.getAsync<AIRepository>()));
  }

  @override
  void dispose() {
    askAIBloc.close();

    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();

    _removeNode();
  }

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMobile) {
      return const SizedBox.shrink();
    }

    final width = _getEditorWidth();

    return BlocProvider.value(
      value: askAIBloc,
      child: BlocListener<AskAIActionBloc, AskAIState>(
        listener: _onListen,
        child: AppFlowyPopover(
          controller: popoverController,
          direction: PopoverDirection.bottomWithLeftAligned,
          triggerActions: PopoverTriggerFlags.none,
          margin: EdgeInsets.zero,
          offset: const Offset(40, 0), // align the editor block
          windowPadding: EdgeInsets.zero,
          constraints: BoxConstraints(maxWidth: width),
          canClose: () async {
            final completer = Completer<bool>();
            final state = askAIBloc.state;
            if (state.result.isEmpty) {
              completer.complete(true);
            } else {
              await showCancelAndConfirmDialog(
                context: context,
                title: LocaleKeys.document_plugins_discardResponse.tr(),
                description: '',
                confirmLabel: LocaleKeys.button_discard.tr(),
                onConfirm: () => completer.complete(true),
                onCancel: () => completer.complete(false),
              );
            }
            return completer.future;
          },
          onClose: _removeNode,
          popupBuilder: (BuildContext popoverContext) {
            return BlocProvider.value(
              // request the result when opening the popover
              value: askAIBloc..add(const AskAIEvent.started()),
              child: const AskAiInputContent(),
            );
          },
          child: const SizedBox(
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  double _getEditorWidth() {
    var width = double.infinity;
    try {
      final editorSize = editorState.renderBox?.size;
      final editorWidth =
          editorSize?.width.clamp(0, editorState.editorStyle.maxWidth ?? width);
      final padding = editorState.editorStyle.padding;
      if (editorWidth != null) {
        width = editorWidth - padding.left - padding.right;
      }
    } catch (_) {}
    return width;
  }

  void _removeNode() {
    final transaction = editorState.transaction..deleteNode(widget.node);
    editorState.apply(transaction);
  }

  void _onListen(BuildContext context, AskAIState state) {
    final error = state.requestError;
    if (error != null) {
      if (error.isLimitExceeded) {
        showAILimitDialog(context, error.message);
      } else {
        showToastNotification(
          context,
          message: error.message,
          type: ToastificationType.error,
        );
      }
    }
  }
}

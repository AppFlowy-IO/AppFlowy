import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SmartEditBlockKeys {
  const SmartEditBlockKeys._();

  static const type = 'smart_edit';

  /// The instruction of the smart edit.
  ///
  /// It is a [SmartEditAction] value.
  static const action = 'action';

  /// The input of the smart edit.
  ///
  /// The content is a string that using '\n\n' as separator.
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

  late final editorState = context.read<EditorState>();
  late final action = SmartEditAction
      .values[widget.node.attributes[SmartEditBlockKeys.action] as int];
  late SmartEditBloc smartEditBloc;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      popoverController.show();
    });

    smartEditBloc = SmartEditBloc(
      node: widget.node,
      editorState: editorState,
      action: action,
    )..add(SmartEditEvent.initial(getIt.getAsync<AIRepository>()));
  }

  @override
  void dispose() {
    smartEditBloc.close();

    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();

    _removeNode();
  }

  @override
  Widget build(BuildContext context) {
    final width = _getEditorWidth();

    return BlocProvider.value(
      value: smartEditBloc,
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
          final state = smartEditBloc.state;
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
            value: smartEditBloc..add(const SmartEditEvent.started()),
            child: const SmartEditInputContent(),
          );
        },
        child: const SizedBox(
          width: double.infinity,
        ),
      ),
    );
  }

  double _getEditorWidth() {
    var width = double.infinity;
    try {
      final editorSize = editorState.renderBox?.size;
      final padding = editorState.editorStyle.padding;
      if (editorSize != null) {
        width = editorSize.width - padding.left - padding.right;
      }
    } catch (_) {}
    return width;
  }

  void _removeNode() {
    final transaction = editorState.transaction..deleteNode(widget.node);
    editorState.apply(transaction);
  }
}

class SmartEditInputContent extends StatelessWidget {
  const SmartEditInputContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmartEditBloc, SmartEditState>(
      builder: (context, state) {
        return Card(
          elevation: 5,
          color: Theme.of(context).colorScheme.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlowyText.medium(
                  state.action.name,
                  fontSize: 14,
                ),
                const VSpace(16),
                state.loading
                    ? _buildLoadingWidget(context)
                    : _buildResultWidget(context, state),
                const VSpace(16),
                const _SmartEditFooterWidget(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultWidget(BuildContext context, SmartEditState state) {
    // todo: replace it with appflowy_editor
    return Flexible(
      child: FlowyText.regular(
        state.result,
        maxLines: null,
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox.square(
        dimension: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}

class _SmartEditFooterWidget extends StatelessWidget {
  const _SmartEditFooterWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedRoundedButton(
          text: LocaleKeys.document_plugins_autoGeneratorRewrite.tr(),
          onTap: () =>
              context.read<SmartEditBloc>().add(const SmartEditEvent.rewrite()),
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.button_replace.tr(),
          onTap: () =>
              context.read<SmartEditBloc>().add(const SmartEditEvent.replace()),
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.button_insertBelow.tr(),
          onTap: () => context
              .read<SmartEditBloc>()
              .add(const SmartEditEvent.insertBelow()),
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.button_cancel.tr(),
          onTap: () =>
              context.read<SmartEditBloc>().add(const SmartEditEvent.cancel()),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            child: Text(
              LocaleKeys.document_plugins_warning.tr(),
              style: TextStyle(color: Theme.of(context).hintColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

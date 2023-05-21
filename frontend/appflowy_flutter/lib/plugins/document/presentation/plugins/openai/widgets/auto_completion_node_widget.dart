import 'dart:convert';
import 'package:appflowy/plugins/document/presentation/plugins/openai/service/openai_client.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/util/learn_more_action.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/discard_dialog.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/loading.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/rewrite_action.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import '../util/editor_extension.dart';

const String kAutoCompletionInputType = 'auto_completion_input';
const String kAutoCompletionInputString = 'auto_completion_input_string';
const String kAutoCompletionGenerationCount =
    'auto_completion_generation_count';
const String kAutoCompletionInputStartSelection =
    'auto_completion_input_start_selection';
const String kAutoCompletionSelectionRange = 'auto_completion_selection_range';

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
  bool isEditingPrompt = false;
  final controller = TextEditingController();
  final focusNode = FocusNode();
  FocusNode textFieldFocusNode = FocusNode();
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
    if (text.isEmpty &&
        widget.node.attributes[kAutoCompletionGenerationCount] < 1) {
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
          _buildInputEditWidget(context),
          _buildFooterWidget(context),
        ],
      );
    }
  }

  Widget _buildInputEditWidget(context) {
    return isEditingPrompt
        ? Column(
            children: [
              Stack(
                children: [
                  _buildInputWidget(context),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: FlowyIconButton(
                      onPressed: () {
                        _onEditPrompt(false);
                      },
                      iconPadding: EdgeInsets.zero,
                      icon: svgWidget(
                        "editor/close",
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      hoverColor: AFThemeExtension.of(context).lightGreyHover,
                      width: 22,
                    ),
                  ),
                ],
              ),
              const Space(0, 10),
            ],
          )
        : Container();
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

  Future<void> _updateGenerationCount() async {
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.node, {
      kAutoCompletionGenerationCount:
          widget.node.attributes[kAutoCompletionGenerationCount] + 1
    });
    await widget.editorState.apply(transaction);
  }

  Widget _buildFooterWidget(BuildContext context) {
    return Row(
      children: [
        PrimaryTextButton(
          LocaleKeys.button_keep.tr(),
          onPressed: () => _onExit(),
        ),
        const Space(10, 0),
        PopoverActionList<RewriteActionWrapper>(
          direction: PopoverDirection.bottomWithLeftAligned,
          offset: const Offset(0, 10),
          actions: RewriteAction.values
              .map((action) => RewriteActionWrapper(action))
              .toList(),
          buildChild: (controller) {
            return SecondaryTextButton(
              LocaleKeys.document_plugins_autoGeneratorRewrite.tr(),
              onPressed: () {
                isEditingPrompt
                    ? _onRewriteActionSelected(RewriteAction.editPrompt)
                    : controller.show();
              },
            );
          },
          onSelected: (action, controller) {
            controller.close();
            if (action.inner == RewriteAction.editPrompt) {
              _onEditPrompt(true);
            } else {
              _onRewriteActionSelected(action.inner);
            }
          },
        ),
        const Space(10, 0),
        SecondaryTextButton(
          LocaleKeys.button_discard.tr(),
          onPressed: () => _onDiscard(),
        ),
      ],
    );
  }

  void _onEditPrompt(bool isEditing) {
    setState(() {
      textFieldFocusNode = FocusNode();
      isEditingPrompt = isEditing;
      controller.text = widget.node.attributes[kAutoCompletionInputString];
    });
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
    int? writeStartPath;
    int? writeEndPath;

    result.fold((userProfile) async {
      BarrierDialog? barrierDialog;
      final openAIRepository = HttpOpenAIRepository(
        client: http.Client(),
        apiKey: userProfile.openaiKey,
      );
      await openAIRepository.getStreamedCompletions(
        prompt: controller.text,
        onStart: () async {
          writeStartPath =
              widget.editorState.document.root.children.last.path.last;
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
          writeEndPath =
              widget.editorState.document.root.children.last.path.last;
          await barrierDialog?.dismiss();
          widget.editorState.service.selectionService.currentSelection
              .addListener(_onCancelWhenSelectionChanged);
          textFieldFocusNode.unfocus();
        },
        onError: (error) async {
          loading.stop();
          await _showError(error.message);
        },
      );
      _updateSelection(writeStartPath, writeEndPath);

      await _updateGenerationCount();
    }, (error) async {
      loading.stop();
      await _showError(
        LocaleKeys.document_plugins_autoGeneratorCantGetOpenAIKey.tr(),
      );
    });
  }

  Future<void> _updateSelection(
    start,
    end,
  ) async {
    final transaction = widget.editorState.transaction;
    final Selection selection;
    if (widget.node.attributes.containsKey(kAutoCompletionSelectionRange)) {
      final previousSelection = Selection.fromJson(
        jsonDecode(widget.node.attributes[kAutoCompletionSelectionRange]),
      );
      selection = widget.editorState.getSelection(
        Selection(
          end: Position(path: [end], offset: 0),
          start: Position(path: previousSelection.start.path, offset: 0),
        ),
      );
    } else {
      selection = widget.editorState.getSelection(
        Selection(
          end: Position(path: [end], offset: 0),
          start: Position(path: [start], offset: 0),
        ),
      );
    }

    Selection updatedSelection =
        selection.copyWith(end: Position(path: [end], offset: 0));
    transaction.updateNode(widget.node, {
      kAutoCompletionSelectionRange: json.encode(updatedSelection.toJson())
    });

    await widget.editorState.apply(transaction);
  }

  String _getAllPreviousText() {
    Selection selection = Selection.fromJson(
      jsonDecode(widget.node.attributes[kAutoCompletionSelectionRange]),
    );
    List<TextNode> textNodesInselection = [];
    for (int i = selection.start.path.last; i < selection.end.path.last; i++) {
      try {
        textNodesInselection
            .add(widget.editorState.document.nodeAtPath([i]) as TextNode);
      } catch (e) {
        continue;
      }
    }
    final previousOutput =
        widget.editorState.getTextInSelection(textNodesInselection, selection);
    return previousOutput.join(" ");
  }

  Future<void> _onRewriteActionSelected(RewriteAction action) async {
    String previousOutput = _getAllPreviousText();
    final loading = Loading(context);
    loading.start();
    int? writeStartPath;
    int? writeEndPath;

    if (action == RewriteAction.makeTextLonger) {
      // clear previous response
      await _onDiscard(exit: false);
    }

    if (action == RewriteAction.editPrompt) {
      // hide input field, clear previous response and update prompt
      setState(() {
        isEditingPrompt = false;
      });
      await _onDiscard(exit: false);
      await _updateEditingText();
    }

    // generate new response
    final result = await UserBackendService.getCurrentUserProfile();
    result.fold((userProfile) async {
      final openAIRepository = HttpOpenAIRepository(
        client: http.Client(),
        apiKey: userProfile.openaiKey,
      );
      await openAIRepository.getStreamedCompletions(
        prompt: action
            .prompt(action == RewriteAction.editPrompt ? text : previousOutput),
        onStart: () async {
          writeStartPath =
              widget.editorState.document.root.children.last.path.last;
          loading.stop();
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
          writeEndPath =
              widget.editorState.document.root.children.last.path.last;
          _updateSelection(writeStartPath, writeEndPath);
          textFieldFocusNode.unfocus();
        },
        onError: (error) async {
          loading.stop();
          await _showError(error.message);
        },
      );
      await _updateGenerationCount();
    }, (error) async {
      loading.stop();
      await _showError(
        LocaleKeys.document_plugins_autoGeneratorCantGetOpenAIKey.tr(),
      );
    });
  }

  Future<void> _onDiscard({bool exit = true}) async {
    Selection selection = Selection.fromJson(
      jsonDecode(widget.node.attributes[kAutoCompletionSelectionRange]),
    );
    final transaction = widget.editorState.transaction;
    transaction.deleteNodesAtPath(
      selection.start.path,
      selection.end.path.last - selection.start.path.last,
    );
    await widget.editorState.apply(transaction);
    if (exit) {
      await _makeSurePreviousNodeIsEmptyTextNode();
      _onExit();
    }
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

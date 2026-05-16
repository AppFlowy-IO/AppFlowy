import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/text_suggestions_toolbar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    hide QuoteBlockKeys, quoteNode;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TurnIntoOptionAction extends CustomActionCell {
  TurnIntoOptionAction({
    required this.editorState,
    required this.blockComponentBuilder,
    required this.mutex,
  });

  final EditorState editorState;
  final Map<String, BlockComponentBuilder> blockComponentBuilder;
  final PopoverController innerController = PopoverController();
  final PopoverMutex mutex;

  @override
  Widget buildWithContext(
    BuildContext context,
    PopoverController controller,
    PopoverMutex? mutex,
  ) {
    return TurnInfoButton(
      editorState: editorState,
      blockComponentBuilder: blockComponentBuilder,
      mutex: this.mutex,
    );
  }
}

class TurnInfoButton extends StatefulWidget {
  const TurnInfoButton({
    super.key,
    required this.editorState,
    required this.blockComponentBuilder,
    required this.mutex,
  });

  final EditorState editorState;
  final Map<String, BlockComponentBuilder> blockComponentBuilder;
  final PopoverMutex mutex;

  @override
  State<TurnInfoButton> createState() => _TurnInfoButtonState();
}

class _TurnInfoButtonState extends State<TurnInfoButton> {
  final PopoverController innerController = PopoverController();
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      asBarrier: true,
      controller: innerController,
      mutex: widget.mutex,
      popupBuilder: (context) {
        isOpen = true;
        return BlocProvider<BlockActionOptionCubit>(
          create: (context) => BlockActionOptionCubit(
            editorState: widget.editorState,
            blockComponentBuilder: widget.blockComponentBuilder,
          ),
          child: BlocBuilder<BlockActionOptionCubit, BlockActionOptionState>(
            builder: (context, _) => _buildTurnIntoOptionMenu(context),
          ),
        );
      },
      onClose: () => isOpen = false,
      direction: PopoverDirection.rightWithCenterAligned,
      animationDuration: Durations.short3,
      beginScaleFactor: 1.0,
      beginOpacity: 0.8,
      child: HoverButton(
        itemHeight: ActionListSizes.itemHeight,
        // todo(lucas): replace the svg with the correct one
        leftIcon: const FlowySvg(FlowySvgs.turninto_s),
        name: LocaleKeys.document_plugins_optionAction_turnInto.tr(),
        onTap: () {
          if (!isOpen) {
            innerController.show();
          }
        },
      ),
    );
  }

  Widget _buildTurnIntoOptionMenu(BuildContext context) {
    final selection = widget.editorState.selection?.normalized;
    // the selection may not be collapsed, for example, if a block contains some children,
    // the selection will be the start from the current block and end at the last child block.
    // we should take care of this case:
    // converting a block that contains children to a heading block,
    //  we should move all the children under the heading block.
    if (selection == null) {
      return const SizedBox.shrink();
    }

    final node = widget.editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return const SizedBox.shrink();
    }

    return TurnIntoOptionMenu(
      node: node,
      hasNonSupportedTypes: _hasNonSupportedTypes(selection),
    );
  }

  bool _hasNonSupportedTypes(Selection selection) {
    final nodes = widget.editorState.getNodesInSelection(selection);
    if (nodes.isEmpty) {
      return false;
    }

    for (final node in nodes) {
      if (!EditorOptionActionType.turnInto.supportTypes.contains(node.type)) {
        return true;
      }
    }

    return false;
  }
}

class TurnIntoOptionMenu extends StatelessWidget {
  const TurnIntoOptionMenu({
    super.key,
    required this.node,
    required this.hasNonSupportedTypes,
  });

  final Node node;

  /// Signifies whether the selection contains [Node]s that are not supported,
  /// these often do not have a [Delta], example could be [FileBlockComponent].
  ///
  final bool hasNonSupportedTypes;

  @override
  Widget build(BuildContext context) {
    if (hasNonSupportedTypes) {
      return buildItem(
        pateItem,
        textSuggestionItem,
        context.read<BlockActionOptionCubit>().editorState,
      );
    }

    return _buildTurnIntoOptions(context, node);
  }

  Widget _buildTurnIntoOptions(BuildContext context, Node node) {
    final editorState = context.read<BlockActionOptionCubit>().editorState;
    SuggestionItem currentSuggestionItem = textSuggestionItem;
    final List<SuggestionItem> suggestionItems = suggestions.sublist(0, 4);
    final List<SuggestionItem> turnIntoItems =
        suggestions.sublist(4, suggestions.length);
    final textColor = Color(0xff99A1A8);

    void refreshSuggestions() {
      final selection = editorState.selection;
      if (selection == null || !selection.isSingle) return;
      final node = editorState.getNodeAtPath(selection.start.path);
      if (node == null || node.delta == null) return;
      final nodeType = node.type;
      SuggestionType? suggestionType;
      if (nodeType == HeadingBlockKeys.type) {
        final level = node.attributes[HeadingBlockKeys.level] ?? 1;
        if (level == 1) {
          suggestionType = SuggestionType.h1;
        } else if (level == 2) {
          suggestionType = SuggestionType.h2;
        } else if (level == 3) {
          suggestionType = SuggestionType.h3;
        }
      } else if (nodeType == ToggleListBlockKeys.type) {
        final level = node.attributes[ToggleListBlockKeys.level];
        if (level == null) {
          suggestionType = SuggestionType.toggle;
        } else if (level == 1) {
          suggestionType = SuggestionType.toggleH1;
        } else if (level == 2) {
          suggestionType = SuggestionType.toggleH2;
        } else if (level == 3) {
          suggestionType = SuggestionType.toggleH3;
        }
      } else {
        suggestionType = nodeType2SuggestionType[nodeType];
      }
      if (suggestionType == null) return;
      suggestionItems.clear();
      turnIntoItems.clear();
      for (final item in suggestions) {
        if (item.type.group == suggestionType.group &&
            item.type != suggestionType) {
          suggestionItems.add(item);
        } else {
          turnIntoItems.add(item);
        }
      }
      currentSuggestionItem =
          suggestions.where((item) => item.type == suggestionType).first;
    }

    refreshSuggestions();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSubTitle(
          LocaleKeys.document_toolbar_suggestions.tr(),
          textColor,
        ),
        ...List.generate(suggestionItems.length, (index) {
          return buildItem(
            suggestionItems[index],
            currentSuggestionItem,
            editorState,
          );
        }),
        buildSubTitle(LocaleKeys.document_toolbar_turnInto.tr(), textColor),
        ...List.generate(turnIntoItems.length, (index) {
          return buildItem(
            turnIntoItems[index],
            currentSuggestionItem,
            editorState,
          );
        }),
      ],
    );
  }

  Widget buildSubTitle(String text, Color color) {
    return Container(
      height: 32,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FlowyText.semibold(
          text,
          color: color,
          figmaLineHeight: 16,
        ),
      ),
    );
  }

  Widget buildItem(
    SuggestionItem item,
    SuggestionItem currentSuggestionItem,
    EditorState state,
  ) {
    final isSelected = item.type == currentSuggestionItem.type;
    return SizedBox(
      height: 36,
      child: FlowyButton(
        leftIconSize: const Size.square(20),
        leftIcon: FlowySvg(item.svg),
        iconPadding: 12,
        text: FlowyText(
          item.title,
          fontWeight: FontWeight.w400,
          figmaLineHeight: 20,
        ),
        rightIcon: isSelected ? FlowySvg(FlowySvgs.toolbar_check_m) : null,
        onTap: () => item.onTap.call(state, false),
      ),
    );
  }
}

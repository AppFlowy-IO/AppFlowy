import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TurnIntoOptionAction extends CustomActionCell {
  TurnIntoOptionAction({
    required this.editorState,
    required this.blockComponentBuilder,
  });

  final EditorState editorState;
  final Map<String, BlockComponentBuilder> blockComponentBuilder;
  final PopoverController innerController = PopoverController();

  @override
  Widget buildWithContext(
    BuildContext context,
    PopoverController controller,
    PopoverMutex? mutex,
  ) {
    return AppFlowyPopover(
      asBarrier: true,
      controller: innerController,
      mutex: mutex,
      popupBuilder: (context) => BlocProvider<BlockActionOptionCubit>(
        create: (_) => BlockActionOptionCubit(
          editorState: editorState,
          blockComponentBuilder: blockComponentBuilder,
        ),
        child: BlocBuilder<BlockActionOptionCubit, BlockActionOptionState>(
          builder: (context, _) => _buildTurnIntoOptionMenu(context),
        ),
      ),
      direction: PopoverDirection.rightWithCenterAligned,
      offset: const Offset(10, 0),
      animationDuration: Durations.short3,
      beginScaleFactor: 1.0,
      beginOpacity: 0.8,
      child: HoverButton(
        itemHeight: ActionListSizes.itemHeight,
        // todo(lucas): replace the svg with the correct one
        leftIcon: const FlowySvg(FlowySvgs.turninto_s),
        name: LocaleKeys.document_plugins_optionAction_turnInto.tr(),
        onTap: innerController.show,
      ),
    );
  }

  Widget _buildTurnIntoOptionMenu(BuildContext context) {
    final selection = editorState.selection?.normalized;
    // the selection may not be collapsed, for example, if a block contains some children,
    // the selection will be the start from the current block and end at the last child block.
    // we should take care of this case:
    // converting a block that contains children to a heading block,
    //  we should move all the children under the heading block.
    if (selection == null) {
      return const SizedBox.shrink();
    }

    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return const SizedBox.shrink();
    }

    return TurnIntoOptionMenu(
      node: node,
      hasNonSupportedTypes: _hasNonSupportedTypes(selection),
    );
  }

  bool _hasNonSupportedTypes(Selection selection) {
    final nodes = editorState.getNodesInSelection(selection);
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _buildTurnIntoOptions(context, node),
    );
  }

  List<Widget> _buildTurnIntoOptions(BuildContext context, Node node) {
    final children = <Widget>[];

    if (hasNonSupportedTypes) {
      return children
        ..add(
          _TurnInfoButton(
            type: SubPageBlockKeys.type,
            node: node,
          ),
        );
    }

    for (final type in EditorOptionActionType.turnInto.supportTypes) {
      if (type == ToggleListBlockKeys.type) {
        // toggle list block and toggle heading block are the same type,
        // but they have different attributes.

        // toggle list block
        children.add(
          _TurnInfoButton(
            type: type,
            node: node,
          ),
        );

        // toggle heading block
        for (final i in [1, 2, 3]) {
          children.add(
            _TurnInfoButton(
              type: type,
              node: node,
              level: i,
            ),
          );
        }
      } else if (type != HeadingBlockKeys.type) {
        children.add(
          _TurnInfoButton(
            type: type,
            node: node,
          ),
        );
      } else {
        for (final i in [1, 2, 3]) {
          children.add(
            _TurnInfoButton(
              type: type,
              node: node,
              level: i,
            ),
          );
        }
      }
    }

    return children;
  }
}

class _TurnInfoButton extends StatelessWidget {
  const _TurnInfoButton({
    required this.type,
    required this.node,
    this.level,
  });

  final String type;
  final Node node;
  final int? level;

  @override
  Widget build(BuildContext context) {
    final name = _buildLocalization(type, level: level);
    final leftIcon = _buildLeftIcon(type, level: level);
    final rightIcon = _buildRightIcon(type, node, level: level);

    return HoverButton(
      name: name,
      leftIcon: FlowySvg(leftIcon),
      rightIcon: rightIcon,
      itemHeight: ActionListSizes.itemHeight,
      onTap: () => context.read<BlockActionOptionCubit>().turnIntoBlock(
            type,
            node,
            level: level,
            currentViewId: getIt<MenuSharedState>().latestOpenView?.id,
          ),
    );
  }

  Widget? _buildRightIcon(String type, Node node, {int? level}) {
    if (type != node.type) {
      return null;
    }

    if (node.type == HeadingBlockKeys.type) {
      final nodeLevel = node.attributes[HeadingBlockKeys.level] ?? 1;
      if (level != nodeLevel) {
        return null;
      }
    }

    if (node.type == ToggleListBlockKeys.type) {
      final nodeLevel = node.attributes[ToggleListBlockKeys.level];
      if (level != nodeLevel) {
        return null;
      }
    }

    return const FlowySvg(
      FlowySvgs.workspace_selected_s,
      blendMode: null,
    );
  }

  FlowySvgData _buildLeftIcon(String type, {int? level}) {
    if (type == ParagraphBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_text_s;
    } else if (type == HeadingBlockKeys.type) {
      switch (level) {
        case 1:
          return FlowySvgs.slash_menu_icon_h1_s;
        case 2:
          return FlowySvgs.slash_menu_icon_h2_s;
        case 3:
          return FlowySvgs.slash_menu_icon_h3_s;
        default:
          return FlowySvgs.slash_menu_icon_text_s;
      }
    } else if (type == QuoteBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_quote_s;
    } else if (type == BulletedListBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_bulleted_list_s;
    } else if (type == NumberedListBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_numbered_list_s;
    } else if (type == TodoListBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_checkbox_s;
    } else if (type == CalloutBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_callout_s;
    } else if (type == SubPageBlockKeys.type) {
      return FlowySvgs.icon_document_s;
    } else if (type == ToggleListBlockKeys.type) {
      switch (level) {
        case 1:
          return FlowySvgs.slash_menu_icon_h1_s;
        case 2:
          return FlowySvgs.slash_menu_icon_h2_s;
        case 3:
          return FlowySvgs.slash_menu_icon_h3_s;
        default:
          return FlowySvgs.slash_menu_icon_toggle_s;
      }
    }

    throw UnimplementedError('Unsupported block type: $type');
  }

  String _buildLocalization(
    String type, {
    int? level,
  }) {
    switch (type) {
      case ParagraphBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_text.tr();
      case HeadingBlockKeys.type:
        switch (level) {
          case 1:
            return LocaleKeys.document_slashMenu_name_heading1.tr();
          case 2:
            return LocaleKeys.document_slashMenu_name_heading2.tr();
          case 3:
            return LocaleKeys.document_slashMenu_name_heading3.tr();
          default:
            return LocaleKeys.document_slashMenu_name_text.tr();
        }
      case QuoteBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_quote.tr();
      case BulletedListBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_bulletedList.tr();
      case NumberedListBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_numberedList.tr();
      case TodoListBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_todoList.tr();
      case CalloutBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_callout.tr();
      case SubPageBlockKeys.type:
        return LocaleKeys.editor_page.tr();
      case ToggleListBlockKeys.type:
        switch (level) {
          case 1:
            return LocaleKeys.document_slashMenu_name_toggleHeading1.tr();
          case 2:
            return LocaleKeys.document_slashMenu_name_toggleHeading2.tr();
          case 3:
            return LocaleKeys.document_slashMenu_name_toggleHeading3.tr();
          default:
            return LocaleKeys.document_slashMenu_name_toggleList.tr();
        }
    }

    throw UnimplementedError('Unsupported block type: $type');
  }
}

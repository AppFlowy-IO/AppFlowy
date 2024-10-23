import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_block_copy_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

/// Build the block component builders.
///
/// Every block type should have a corresponding builder in the map.
/// Otherwise, the errorBlockComponentBuilder will be rendered.
///
/// Additional, you can define the block render options in the builder
/// - customize the block option actions. (... button and + button)
/// - customize the block component configuration. (padding, placeholder, etc.)
/// - customize the block icon. (bulleted list, numbered list, todo list)
/// - customize the hover menu. (show the menu at the top-right corner of the block)
Map<String, BlockComponentBuilder> buildBlockComponentBuilders({
  required BuildContext context,
  required EditorState editorState,
  required EditorStyleCustomizer styleCustomizer,
  List<SelectionMenuItem>? slashMenuItems,
  bool editable = true,
  ShowPlaceholder? showParagraphPlaceholder,
  String Function(Node)? placeholderText,
  EdgeInsets? customHeadingPadding,
}) {
  final configuration = _buildDefaultConfiguration(context);
  final builders = _buildBlockComponentBuilderMap(
    context,
    configuration: configuration,
    editorState: editorState,
    styleCustomizer: styleCustomizer,
    showParagraphPlaceholder: showParagraphPlaceholder,
    placeholderText: placeholderText,
  );

  // customize the action builder. actually, we can customize them in their own builder. Put them here just for convenience.
  if (editable) {
    _customBlockOptionActions(
      context,
      builders: builders,
      editorState: editorState,
      styleCustomizer: styleCustomizer,
      slashMenuItems: slashMenuItems,
    );
  }

  return builders;
}

BlockComponentConfiguration _buildDefaultConfiguration(BuildContext context) {
  final configuration = BlockComponentConfiguration(
    padding: (_) {
      if (UniversalPlatform.isMobile) {
        final pageStyle = context.read<DocumentPageStyleBloc>().state;
        final factor = pageStyle.fontLayout.factor;
        final padding = pageStyle.lineHeightLayout.padding * factor;
        return EdgeInsets.only(top: padding);
      }

      return const EdgeInsets.symmetric(vertical: 5.0);
    },
    indentPadding: (node, textDirection) => textDirection == TextDirection.ltr
        ? const EdgeInsets.only(left: 26.0)
        : const EdgeInsets.only(right: 26.0),
  );
  return configuration;
}

/// Build the option actions for the block component.
///
/// Notes: different block type may have different option actions.
/// All the block types have the delete and duplicate options.
List<OptionAction> _buildOptionActions(BuildContext context, String type) {
  final standardActions = [
    OptionAction.delete,
    OptionAction.duplicate,
  ];

  // filter out the copy link to block option if in local mode
  if (context.read<DocumentBloc?>()?.isLocalMode != true) {
    standardActions.add(OptionAction.copyLinkToBlock);
  }

  if (EditorOptionActionType.turnInto.supportTypes.contains(type)) {
    standardActions.add(OptionAction.turnInto);
  }

  if (EditorOptionActionType.color.supportTypes.contains(type)) {
    standardActions.addAll([OptionAction.divider, OptionAction.color]);
  }

  if (EditorOptionActionType.align.supportTypes.contains(type)) {
    standardActions.addAll([OptionAction.divider, OptionAction.align]);
  }

  if (EditorOptionActionType.depth.supportTypes.contains(type)) {
    standardActions.addAll([OptionAction.divider, OptionAction.depth]);
  }

  return standardActions;
}

void _customBlockOptionActions(
  BuildContext context, {
  required Map<String, BlockComponentBuilder> builders,
  required EditorState editorState,
  required EditorStyleCustomizer styleCustomizer,
  List<SelectionMenuItem>? slashMenuItems,
}) {
  for (final entry in builders.entries) {
    if (entry.key == PageBlockKeys.type) {
      continue;
    }
    final builder = entry.value;
    final actions = _buildOptionActions(context, entry.key);

    if (UniversalPlatform.isDesktop) {
      builder.showActions =
          (node) => node.parent?.type != TableCellBlockKeys.type;
      builder.configuration = builder.configuration.copyWith(
        blockSelectionAreaMargin: (_) => const EdgeInsets.symmetric(
          vertical: 1,
        ),
      );

      builder.actionBuilder = (context, state) {
        final top = builder.configuration.padding(context.node).top;
        final padding = context.node.type == HeadingBlockKeys.type
            ? EdgeInsets.only(top: top + 8.0)
            : EdgeInsets.only(top: top + 2.0);
        return Padding(
          padding: padding,
          child: BlockActionList(
            blockComponentContext: context,
            blockComponentState: state,
            editorState: editorState,
            blockComponentBuilder: builders,
            actions: actions,
            showSlashMenu: slashMenuItems != null
                ? () => customSlashCommand(
                      slashMenuItems,
                      shouldInsertSlash: false,
                      style: styleCustomizer.selectionMenuStyleBuilder(),
                    ).handler.call(editorState)
                : () {},
          ),
        );
      };
    }
  }
}

Map<String, BlockComponentBuilder> _buildBlockComponentBuilderMap(
  BuildContext context, {
  required BlockComponentConfiguration configuration,
  required EditorState editorState,
  required EditorStyleCustomizer styleCustomizer,
  ShowPlaceholder? showParagraphPlaceholder,
  String Function(Node)? placeholderText,
  EdgeInsets? customHeadingPadding,
}) {
  final customBlockComponentBuilderMap = {
    PageBlockKeys.type: PageBlockComponentBuilder(),
    ParagraphBlockKeys.type: _buildParagraphBlockComponentBuilder(
      context,
      configuration,
      showParagraphPlaceholder,
      placeholderText,
    ),
    TodoListBlockKeys.type: _buildTodoListBlockComponentBuilder(
      context,
      configuration,
    ),
    BulletedListBlockKeys.type: _buildBulletedListBlockComponentBuilder(
      context,
      configuration,
    ),
    NumberedListBlockKeys.type: _buildNumberedListBlockComponentBuilder(
      context,
      configuration,
    ),
    QuoteBlockKeys.type: _buildQuoteBlockComponentBuilder(
      context,
      configuration,
    ),
    HeadingBlockKeys.type: _buildHeadingBlockComponentBuilder(
      context,
      configuration,
      styleCustomizer,
      customHeadingPadding,
    ),
    ImageBlockKeys.type: _buildCustomImageBlockComponentBuilder(
      context,
      configuration,
    ),
    MultiImageBlockKeys.type: _buildMultiImageBlockComponentBuilder(
      context,
      configuration,
    ),
    TableBlockKeys.type: _buildTableBlockComponentBuilder(
      context,
      configuration,
    ),
    TableCellBlockKeys.type: _buildTableCellBlockComponentBuilder(
      context,
      configuration,
    ),
    DatabaseBlockKeys.gridType: _buildDatabaseViewBlockComponentBuilder(
      context,
      configuration,
    ),
    DatabaseBlockKeys.boardType: _buildDatabaseViewBlockComponentBuilder(
      context,
      configuration,
    ),
    DatabaseBlockKeys.calendarType: _buildDatabaseViewBlockComponentBuilder(
      context,
      configuration,
    ),
    CalloutBlockKeys.type: _buildCalloutBlockComponentBuilder(
      context,
      configuration,
    ),
    DividerBlockKeys.type: _buildDividerBlockComponentBuilder(
      context,
      configuration,
      editorState,
    ),
    MathEquationBlockKeys.type: _buildMathEquationBlockComponentBuilder(
      context,
      configuration,
    ),
    CodeBlockKeys.type: _buildCodeBlockComponentBuilder(
      context,
      configuration,
      styleCustomizer,
    ),
    AutoCompletionBlockKeys.type: _buildAutoCompletionBlockComponentBuilder(
      context,
      configuration,
    ),
    SmartEditBlockKeys.type: _buildSmartEditBlockComponentBuilder(
      context,
      configuration,
    ),
    ToggleListBlockKeys.type: _buildToggleListBlockComponentBuilder(
      context,
      configuration,
      styleCustomizer,
      customHeadingPadding,
    ),
    OutlineBlockKeys.type: _buildOutlineBlockComponentBuilder(
      context,
      configuration,
      styleCustomizer,
    ),
    LinkPreviewBlockKeys.type: _buildLinkPreviewBlockComponentBuilder(
      context,
      configuration,
    ),
    FileBlockKeys.type: _buildFileBlockComponentBuilder(
      context,
      configuration,
    ),
    SubPageBlockKeys.type: _buildSubPageBlockComponentBuilder(
      context,
      configuration,
    ),
    errorBlockComponentBuilderKey: ErrorBlockComponentBuilder(
      configuration: configuration,
    ),
  };

  final builders = {
    ...standardBlockComponentBuilderMap,
    ...customBlockComponentBuilderMap,
  };

  return builders;
}

ParagraphBlockComponentBuilder _buildParagraphBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
  ShowPlaceholder? showParagraphPlaceholder,
  String Function(Node)? placeholderText,
) {
  return ParagraphBlockComponentBuilder(
    configuration: configuration.copyWith(placeholderText: placeholderText),
    showPlaceholder: showParagraphPlaceholder,
  );
}

TodoListBlockComponentBuilder _buildTodoListBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return TodoListBlockComponentBuilder(
    configuration: configuration.copyWith(
      placeholderText: (_) => LocaleKeys.blockPlaceholders_todoList.tr(),
    ),
    iconBuilder: (_, node, onCheck) => TodoListIcon(
      node: node,
      onCheck: onCheck,
    ),
    toggleChildrenTriggers: [
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ],
  );
}

BulletedListBlockComponentBuilder _buildBulletedListBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return BulletedListBlockComponentBuilder(
    configuration: configuration.copyWith(
      placeholderText: (_) => LocaleKeys.blockPlaceholders_bulletList.tr(),
    ),
    iconBuilder: (_, node) => BulletedListIcon(node: node),
  );
}

NumberedListBlockComponentBuilder _buildNumberedListBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return NumberedListBlockComponentBuilder(
    configuration: configuration.copyWith(
      placeholderText: (_) => LocaleKeys.blockPlaceholders_numberList.tr(),
    ),
    iconBuilder: (_, node, textDirection) => NumberedListIcon(
      node: node,
      textDirection: textDirection,
    ),
  );
}

QuoteBlockComponentBuilder _buildQuoteBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return QuoteBlockComponentBuilder(
    configuration: configuration.copyWith(
      placeholderText: (_) => LocaleKeys.blockPlaceholders_quote.tr(),
    ),
  );
}

HeadingBlockComponentBuilder _buildHeadingBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
  EditorStyleCustomizer styleCustomizer,
  EdgeInsets? customHeadingPadding,
) {
  return HeadingBlockComponentBuilder(
    configuration: configuration.copyWith(
      padding: (node) {
        if (customHeadingPadding != null) {
          return customHeadingPadding;
        }

        if (UniversalPlatform.isMobile) {
          final pageStyle = context.read<DocumentPageStyleBloc>().state;
          final factor = pageStyle.fontLayout.factor;
          final headingPaddings =
              pageStyle.lineHeightLayout.headingPaddings.map((e) => e * factor);
          int level = node.attributes[HeadingBlockKeys.level] ?? 6;
          level = level.clamp(1, 6);
          return EdgeInsets.only(top: headingPaddings.elementAt(level - 1));
        }

        return const EdgeInsets.only(top: 12.0, bottom: 4.0);
      },
      placeholderText: (node) {
        int level = node.attributes[HeadingBlockKeys.level] ?? 6;
        level = level.clamp(1, 6);
        return LocaleKeys.blockPlaceholders_heading.tr(
          args: [level.toString()],
        );
      },
    ),
    textStyleBuilder: (level) => styleCustomizer.headingStyleBuilder(level),
  );
}

CustomImageBlockComponentBuilder _buildCustomImageBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return CustomImageBlockComponentBuilder(
    configuration: configuration,
    showMenu: true,
    menuBuilder: (node, state) => Positioned(
      top: 10,
      right: 10,
      child: ImageMenu(node: node, state: state),
    ),
  );
}

MultiImageBlockComponentBuilder _buildMultiImageBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return MultiImageBlockComponentBuilder(
    configuration: configuration,
    showMenu: true,
    menuBuilder: (
      Node node,
      MultiImageBlockComponentState state,
      ValueNotifier<int> indexNotifier,
      VoidCallback onImageDeleted,
    ) =>
        Positioned(
      top: 10,
      right: 10,
      child: MultiImageMenu(
        node: node,
        state: state,
        indexNotifier: indexNotifier,
        isLocalMode: context.read<DocumentBloc>().isLocalMode,
        onImageDeleted: onImageDeleted,
      ),
    ),
  );
}

TableBlockComponentBuilder _buildTableBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return TableBlockComponentBuilder(
    menuBuilder: (node, editorState, position, dir, onBuild, onClose) =>
        TableMenu(
      node: node,
      editorState: editorState,
      position: position,
      dir: dir,
      onBuild: onBuild,
      onClose: onClose,
    ),
  );
}

TableCellBlockComponentBuilder _buildTableCellBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return TableCellBlockComponentBuilder(
    colorBuilder: (context, node) {
      final String colorString =
          node.attributes[TableCellBlockKeys.colBackgroundColor] ??
              node.attributes[TableCellBlockKeys.rowBackgroundColor] ??
              '';
      if (colorString.isEmpty) {
        return null;
      }
      return buildEditorCustomizedColor(context, node, colorString);
    },
    menuBuilder: (node, editorState, position, dir, onBuild, onClose) =>
        TableMenu(
      node: node,
      editorState: editorState,
      position: position,
      dir: dir,
      onBuild: onBuild,
      onClose: onClose,
    ),
  );
}

DatabaseViewBlockComponentBuilder _buildDatabaseViewBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return DatabaseViewBlockComponentBuilder(
    configuration: configuration.copyWith(
      padding: (_) => const EdgeInsets.symmetric(vertical: 10),
    ),
  );
}

CalloutBlockComponentBuilder _buildCalloutBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  final calloutBGColor = AFThemeExtension.of(context).calloutBGColor;
  return CalloutBlockComponentBuilder(
    configuration: configuration.copyWith(
      padding: (node) => const EdgeInsets.symmetric(vertical: 10),
    ),
    inlinePadding: const EdgeInsets.symmetric(vertical: 8.0),
    defaultColor: calloutBGColor,
  );
}

DividerBlockComponentBuilder _buildDividerBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
  EditorState editorState,
) {
  return DividerBlockComponentBuilder(
    configuration: configuration,
    height: 28.0,
    wrapper: (_, node, child) => MobileBlockActionButtons(
      showThreeDots: false,
      node: node,
      editorState: editorState,
      child: child,
    ),
  );
}

MathEquationBlockComponentBuilder _buildMathEquationBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return MathEquationBlockComponentBuilder(
    configuration: configuration,
  );
}

CodeBlockComponentBuilder _buildCodeBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
  EditorStyleCustomizer styleCustomizer,
) {
  return CodeBlockComponentBuilder(
    configuration: configuration.copyWith(
      textStyle: (_) => styleCustomizer.codeBlockStyleBuilder(),
      placeholderTextStyle: (_) => styleCustomizer.codeBlockStyleBuilder(),
    ),
    styleBuilder: () => CodeBlockStyle(
      backgroundColor: AFThemeExtension.of(context).calloutBGColor,
      foregroundColor: AFThemeExtension.of(context).textColor.withAlpha(155),
    ),
    padding: const EdgeInsets.only(left: 20, right: 30, bottom: 34),
    languagePickerBuilder: codeBlockLanguagePickerBuilder,
    copyButtonBuilder: codeBlockCopyBuilder,
    showLineNumbers: false,
  );
}

AutoCompletionBlockComponentBuilder _buildAutoCompletionBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return AutoCompletionBlockComponentBuilder();
}

SmartEditBlockComponentBuilder _buildSmartEditBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return SmartEditBlockComponentBuilder();
}

ToggleListBlockComponentBuilder _buildToggleListBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
  EditorStyleCustomizer styleCustomizer,
  EdgeInsets? customHeadingPadding,
) {
  return ToggleListBlockComponentBuilder(
    configuration: configuration.copyWith(
      padding: (node) {
        if (customHeadingPadding != null) {
          return customHeadingPadding;
        }

        if (UniversalPlatform.isMobile) {
          final pageStyle = context.read<DocumentPageStyleBloc>().state;
          final factor = pageStyle.fontLayout.factor;
          final headingPaddings =
              pageStyle.lineHeightLayout.headingPaddings.map((e) => e * factor);
          int level = node.attributes[HeadingBlockKeys.level] ?? 6;
          level = level.clamp(1, 6);
          return EdgeInsets.only(top: headingPaddings.elementAt(level - 1));
        }

        return const EdgeInsets.only(top: 12.0, bottom: 4.0);
      },
      textStyle: (node) {
        final level = node.attributes[ToggleListBlockKeys.level] as int?;
        if (level == null) {
          return configuration.textStyle(node);
        }
        return styleCustomizer.headingStyleBuilder(level);
      },
      placeholderText: (node) {
        int? level = node.attributes[ToggleListBlockKeys.level];
        if (level == null) {
          return configuration.placeholderText(node);
        }
        level = level.clamp(1, 6);
        return LocaleKeys.blockPlaceholders_heading.tr(
          args: [level.toString()],
        );
      },
    ),
    textStyleBuilder: (level) => styleCustomizer.headingStyleBuilder(level),
  );
}

OutlineBlockComponentBuilder _buildOutlineBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
  EditorStyleCustomizer styleCustomizer,
) {
  return OutlineBlockComponentBuilder(
    configuration: configuration.copyWith(
      placeholderTextStyle: (_) =>
          styleCustomizer.outlineBlockPlaceholderStyleBuilder(),
      padding: (_) => const EdgeInsets.only(top: 12.0, bottom: 4.0),
    ),
  );
}

LinkPreviewBlockComponentBuilder _buildLinkPreviewBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return LinkPreviewBlockComponentBuilder(
    configuration: configuration.copyWith(
      padding: (_) => const EdgeInsets.symmetric(vertical: 10),
    ),
    cache: LinkPreviewDataCache(),
    showMenu: true,
    menuBuilder: (context, node, state) => Positioned(
      top: 10,
      right: 0,
      child: LinkPreviewMenu(node: node, state: state),
    ),
    builder: (_, node, url, title, description, imageUrl) =>
        CustomLinkPreviewWidget(
      node: node,
      url: url,
      title: title,
      description: description,
      imageUrl: imageUrl,
    ),
  );
}

FileBlockComponentBuilder _buildFileBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return FileBlockComponentBuilder(configuration: configuration);
}

SubPageBlockComponentBuilder _buildSubPageBlockComponentBuilder(
  BuildContext context,
  BlockComponentConfiguration configuration,
) {
  return SubPageBlockComponentBuilder(configuration: configuration);
}

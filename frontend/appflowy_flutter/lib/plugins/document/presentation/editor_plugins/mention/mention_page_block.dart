import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mobile_page_selector_sheet.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/shared/clipboard_state.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show
        ApplyOptions,
        Delta,
        EditorState,
        Node,
        NodeIterator,
        Path,
        Position,
        Selection,
        SelectionType,
        TextInsert,
        TextTransaction,
        paragraphNode;
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

final pageMemorizer = <String, ViewPB?>{};

Node pageMentionNode(String viewId) {
  return paragraphNode(
    delta: Delta(
      operations: [
        TextInsert(
          MentionBlockKeys.mentionChar,
          attributes: {
            MentionBlockKeys.mention: {
              MentionBlockKeys.type: MentionType.page.name,
              MentionBlockKeys.pageId: viewId,
            },
          },
        ),
      ],
    ),
  );
}

class MentionPageBlock extends StatefulWidget {
  const MentionPageBlock({
    super.key,
    required this.editorState,
    required this.pageId,
    required this.blockId,
    required this.node,
    required this.textStyle,
    required this.index,
    required this.isSubPage,
  });

  final EditorState editorState;
  final String pageId;
  final String? blockId;
  final Node node;
  final TextStyle? textStyle;
  final bool isSubPage;

  // Used to update the block
  final int index;

  @override
  State<MentionPageBlock> createState() => _MentionPageBlockState();
}

class _MentionPageBlockState extends State<MentionPageBlock> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MentionPageBloc(
        pageId: widget.pageId,
        blockId: widget.isSubPage ? null : widget.blockId,
        isSubPage: widget.isSubPage,
      )..add(const MentionPageEvent.initial()),
      child: BlocBuilder<MentionPageBloc, MentionPageState>(
        builder: (context, state) {
          final view = state.view;
          if (state.isLoading) {
            return const SizedBox.shrink();
          }

          if (state.isDeleted || view == null) {
            return _NoAccessMentionPageBlock(
              textStyle: widget.textStyle,
            );
          }

          if (UniversalPlatform.isMobile) {
            return _MobileMentionPageBlock(
              view: view,
              content: state.blockContent,
              textStyle: widget.textStyle,
              handleTap: () => _handleTap(
                context,
                widget.editorState,
                view,
                blockId: widget.blockId,
              ),
              handleDoubleTap: () => _handleDoubleTap(
                context,
                widget.editorState,
                view.id,
                widget.node,
                widget.index,
              ),
            );
          } else {
            return _DesktopMentionPageBlock(
              view: view,
              content: state.blockContent,
              textStyle: widget.textStyle,
              showTrashHint: state.isInTrash,
              handleTap: () => _handleTap(
                context,
                widget.editorState,
                view,
                blockId: widget.blockId,
              ),
            );
          }
        },
      ),
    );
  }

  void updateSelection() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.editorState
          .updateSelectionWithReason(widget.editorState.selection),
    );
  }
}

class MentionSubPageBlock extends StatefulWidget {
  const MentionSubPageBlock({
    super.key,
    required this.editorState,
    required this.pageId,
    required this.node,
    required this.textStyle,
    required this.index,
  });

  final EditorState editorState;
  final String pageId;
  final Node node;
  final TextStyle? textStyle;

  // Used to update the block
  final int index;

  @override
  State<MentionSubPageBlock> createState() => _MentionSubPageBlockState();
}

class _MentionSubPageBlockState extends State<MentionSubPageBlock> {
  late bool isHandlingPaste = context.read<ClipboardState>().isHandlingPaste;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MentionPageBloc(pageId: widget.pageId, isSubPage: true)
        ..add(const MentionPageEvent.initial()),
      child: BlocConsumer<MentionPageBloc, MentionPageState>(
        listener: (context, state) async {
          if (state.view != null) {
            final currentViewId = getIt<MenuSharedState>().latestOpenView?.id;
            if (currentViewId == null) {
              return;
            }

            if (state.view!.parentViewId != currentViewId) {
              turnIntoPageRef();
            }
          }
        },
        builder: (context, state) {
          final view = state.view;
          if (state.isLoading || isHandlingPaste) {
            return const SizedBox.shrink();
          }

          if (state.isDeleted || view == null) {
            return _DeletedPageBlock(textStyle: widget.textStyle);
          }

          if (UniversalPlatform.isMobile) {
            return _MobileMentionPageBlock(
              view: view,
              showTrashHint: state.isInTrash,
              textStyle: widget.textStyle,
              handleTap: () => _handleTap(context, widget.editorState, view),
              isChildPage: true,
              content: '',
              handleDoubleTap: () => _handleDoubleTap(
                context,
                widget.editorState,
                view.id,
                widget.node,
                widget.index,
              ),
            );
          } else {
            return _DesktopMentionPageBlock(
              view: view,
              showTrashHint: state.isInTrash,
              content: null,
              textStyle: widget.textStyle,
              isChildPage: true,
              handleTap: () => _handleTap(context, widget.editorState, view),
            );
          }
        },
      ),
    );
  }

  Future<ViewPB?> fetchView(String pageId) async {
    final view = await ViewBackendService.getView(pageId).then(
      (value) => value.toNullable(),
    );

    if (view == null) {
      // try to fetch from trash
      final trashViews = await TrashService().readTrash();
      final trash = trashViews.fold(
        (l) => l.items.firstWhereOrNull((element) => element.id == pageId),
        (r) => null,
      );
      if (trash != null) {
        return ViewPB()
          ..id = trash.id
          ..name = trash.name;
      }
    }

    return view;
  }

  void updateSelection() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.editorState
          .updateSelectionWithReason(widget.editorState.selection),
    );
  }

  void turnIntoPageRef() {
    final transaction = widget.editorState.transaction
      ..formatText(
        widget.node,
        widget.index,
        MentionBlockKeys.mentionChar.length,
        {
          MentionBlockKeys.mention: {
            MentionBlockKeys.type: MentionType.page.name,
            MentionBlockKeys.pageId: widget.pageId,
          },
        },
      );

    widget.editorState.apply(
      transaction,
      withUpdateSelection: false,
      options: const ApplyOptions(
        recordUndo: false,
      ),
    );
  }
}

Path? _findNodePathByBlockId(EditorState editorState, String blockId) {
  final document = editorState.document;
  final startNode = document.root.children.firstOrNull;
  if (startNode == null) {
    return null;
  }

  final nodeIterator = NodeIterator(
    document: document,
    startNode: startNode,
  );
  while (nodeIterator.moveNext()) {
    final node = nodeIterator.current;
    if (node.id == blockId) {
      return node.path;
    }
  }

  return null;
}

Future<void> _handleTap(
  BuildContext context,
  EditorState editorState,
  ViewPB view, {
  String? blockId,
}) async {
  final currentViewId = context.read<DocumentBloc>().documentId;
  if (currentViewId == view.id && blockId != null) {
    // same page
    final path = _findNodePathByBlockId(editorState, blockId);
    if (path != null) {
      editorState.scrollService?.jumpTo(path.first);
      await editorState.updateSelectionWithReason(
        Selection.collapsed(Position(path: path)),
        customSelectionType: SelectionType.block,
      );
    }
    return;
  }

  if (UniversalPlatform.isMobile) {
    if (context.mounted && currentViewId != view.id) {
      await context.pushView(view);
    }
  } else {
    final action = NavigationAction(
      objectId: view.id,
      arguments: {
        ActionArgumentKeys.view: view,
        ActionArgumentKeys.blockId: blockId,
      },
    );
    getIt<ActionNavigationBloc>().add(
      ActionNavigationEvent.performAction(
        action: action,
      ),
    );
  }
}

Future<void> _handleDoubleTap(
  BuildContext context,
  EditorState editorState,
  String viewId,
  Node node,
  int index,
) async {
  if (!UniversalPlatform.isMobile) {
    return;
  }

  final currentViewId = context.read<DocumentBloc>().documentId;
  final newViewId = await showPageSelectorSheet(
    context,
    currentViewId: currentViewId,
    selectedViewId: viewId,
  );

  if (newViewId != null) {
    // Update this nodes pageId
    final transaction = editorState.transaction
      ..formatText(
        node,
        index,
        1,
        {
          MentionBlockKeys.mention: {
            MentionBlockKeys.type: MentionType.page.name,
            MentionBlockKeys.pageId: newViewId,
          },
        },
      );

    await editorState.apply(transaction, withUpdateSelection: false);
  }
}

class _MentionPageBlockContent extends StatelessWidget {
  const _MentionPageBlockContent({
    required this.view,
    required this.textStyle,
    this.content,
    this.showTrashHint = false,
    this.isChildPage = false,
  });

  final ViewPB view;
  final TextStyle? textStyle;
  final String? content;
  final bool showTrashHint;
  final bool isChildPage;

  @override
  Widget build(BuildContext context) {
    final text = _getDisplayText(context, view, content);
    final emojiSize = textStyle?.fontSize ?? 12.0;
    final iconSize = textStyle?.fontSize ?? 16.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_shouldDisplayViewName(context, view.id, content)) ...[
          const HSpace(4),
          view.icon.value.isNotEmpty
              ? FlowyText.emoji(
                  view.icon.value,
                  fontSize: emojiSize,
                  lineHeight: textStyle?.height,
                  optimizeEmojiAlign: true,
                )
              : FlowySvg(
                  view.layout.mentionIcon(isChildPage: isChildPage),
                  size: Size.square(iconSize + 2.0),
                ),
        ],
        const HSpace(2),
        Flexible(
          child: FlowyText(
            text,
            decoration: TextDecoration.underline,
            fontSize: textStyle?.fontSize,
            fontWeight: textStyle?.fontWeight,
            lineHeight: textStyle?.height,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showTrashHint) ...[
          FlowyText(
            LocaleKeys.document_mention_trashHint.tr(),
            fontSize: textStyle?.fontSize,
            fontWeight: textStyle?.fontWeight,
            lineHeight: textStyle?.height,
            color: Theme.of(context).disabledColor,
            decoration: TextDecoration.underline,
            decorationColor: AFThemeExtension.of(context).textColor,
          ),
        ],
        const HSpace(4),
      ],
    );
  }

  String _getDisplayText(
    BuildContext context,
    ViewPB view,
    String? blockContent,
  ) {
    final shouldDisplayViewName = _shouldDisplayViewName(
      context,
      view.id,
      blockContent,
    );

    if (blockContent == null || blockContent.isEmpty) {
      return shouldDisplayViewName ? view.name : '';
    }

    return shouldDisplayViewName
        ? '${view.name} - $blockContent'
        : blockContent;
  }

  // display the view name or not
  // if the block is from the same doc,
  // 1. block content is not empty, display the **block content only**.
  // 2. block content is empty, display the **view name**.
  // if the block is from another doc,
  // 1. block content is not empty, display the **view name and block content**.
  // 2. block content is empty, display the **view name**.
  bool _shouldDisplayViewName(
    BuildContext context,
    String viewId,
    String? blockContent,
  ) {
    if (_isSameDocument(context, viewId)) {
      return blockContent == null || blockContent.isEmpty;
    }
    return true;
  }

  bool _isSameDocument(BuildContext context, String viewId) {
    final currentViewId = context.read<DocumentBloc?>()?.documentId;
    return viewId == currentViewId;
  }
}

class _NoAccessMentionPageBlock extends StatelessWidget {
  const _NoAccessMentionPageBlock({required this.textStyle});

  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FlowyText(
          LocaleKeys.document_mention_noAccess.tr(),
          color: Theme.of(context).disabledColor,
          decoration: TextDecoration.underline,
          fontSize: textStyle?.fontSize,
          fontWeight: textStyle?.fontWeight,
        ),
      ),
    );
  }
}

class _DeletedPageBlock extends StatelessWidget {
  const _DeletedPageBlock({required this.textStyle});

  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FlowyText(
          LocaleKeys.document_mention_deletedPage.tr(),
          color: Theme.of(context).disabledColor,
          decoration: TextDecoration.underline,
          fontSize: textStyle?.fontSize,
          fontWeight: textStyle?.fontWeight,
        ),
      ),
    );
  }
}

class _MobileMentionPageBlock extends StatelessWidget {
  const _MobileMentionPageBlock({
    required this.view,
    required this.content,
    required this.textStyle,
    required this.handleTap,
    required this.handleDoubleTap,
    this.showTrashHint = false,
    this.isChildPage = false,
  });

  final TextStyle? textStyle;
  final ViewPB view;
  final String content;
  final VoidCallback handleTap;
  final VoidCallback handleDoubleTap;
  final bool showTrashHint;
  final bool isChildPage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      onDoubleTap: handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: _MentionPageBlockContent(
        view: view,
        content: content,
        textStyle: textStyle,
        showTrashHint: showTrashHint,
        isChildPage: isChildPage,
      ),
    );
  }
}

class _DesktopMentionPageBlock extends StatelessWidget {
  const _DesktopMentionPageBlock({
    required this.view,
    required this.textStyle,
    required this.handleTap,
    required this.content,
    this.showTrashHint = false,
    this.isChildPage = false,
  });

  final TextStyle? textStyle;
  final ViewPB view;
  final String? content;
  final VoidCallback handleTap;
  final bool showTrashHint;
  final bool isChildPage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FlowyHover(
          cursor: SystemMouseCursors.click,
          child: _MentionPageBlockContent(
            view: view,
            content: content,
            textStyle: textStyle,
            showTrashHint: showTrashHint,
            isChildPage: isChildPage,
          ),
        ),
      ),
    );
  }
}

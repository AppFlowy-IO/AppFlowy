import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mobile_page_selector_sheet.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show Delta, EditorState, Node, TextInsert, TextTransaction, paragraphNode;
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
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
          '\$',
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
  });

  final EditorState editorState;
  final String pageId;
  final String? blockId;
  final Node node;
  final TextStyle? textStyle;

  // Used to update the block
  final int index;

  @override
  State<MentionPageBlock> createState() => _MentionPageBlockState();
}

class _MentionPageBlockState extends State<MentionPageBlock> {
  late final EditorState editorState;

  @override
  void initState() {
    super.initState();

    editorState = context.read<EditorState>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MentionPageBloc(
        pageId: widget.pageId,
        blockId: widget.blockId,
      )..add(const MentionPageEvent.initial()),
      child: BlocBuilder<MentionPageBloc, MentionPageState>(
        builder: (context, state) {
          final view = state.view;
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.isDeleted || view == null) {
            return _NoAccessMentionPageBlock(
              textStyle: widget.textStyle,
            );
          }

          if (UniversalPlatform.isMobile) {
            return _MobileMentionPageBlock(
              view: view,
              textStyle: widget.textStyle,
              handleTap: () => handleTap(view),
              handleDoubleTap: handleDoubleTap,
            );
          } else {
            return _DesktopMentionPageBlock(
              view: view,
              textStyle: widget.textStyle,
              handleTap: () => handleTap(view),
            );
          }
        },
      ),
    );
  }

  Future<void> handleTap(ViewPB view) async {
    final view = await fetchView(widget.pageId);
    if (view == null) {
      Log.error('Page(${widget.pageId}) not found');
      return;
    }

    if (UniversalPlatform.isMobile && mounted) {
      await context.pushView(view);
    } else {
      getIt<TabsBloc>().add(
        TabsEvent.openPlugin(plugin: view.plugin(), view: view),
      );
    }
  }

  Future<void> handleDoubleTap() async {
    if (!UniversalPlatform.isMobile) {
      return;
    }

    final currentViewId = context.read<DocumentBloc>().documentId;
    final viewId = await showPageSelectorSheet(
      context,
      currentViewId: currentViewId,
      selectedViewId: widget.pageId,
    );

    if (viewId != null) {
      // Update this nodes pageId
      final transaction = widget.editorState.transaction
        ..formatText(
          widget.node,
          widget.index,
          1,
          {
            MentionBlockKeys.mention: {
              MentionBlockKeys.type: MentionType.page.name,
              MentionBlockKeys.pageId: viewId,
            },
          },
        );

      await widget.editorState.apply(transaction, withUpdateSelection: false);
    }
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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      editorState.updateSelectionWithReason(
        editorState.selection,
      );
    });
  }
}

class _MentionPageBlockContent extends StatelessWidget {
  const _MentionPageBlockContent({
    required this.view,
    required this.textStyle,
  });

  final ViewPB view;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final emojiSize = textStyle?.fontSize ?? 12.0;
    final iconSize = textStyle?.fontSize ?? 16.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HSpace(4),
        view.icon.value.isNotEmpty
            ? FlowyText.emoji(
                view.icon.value,
                fontSize: emojiSize,
                lineHeight: textStyle?.height,
                optimizeEmojiAlign: true,
              )
            : FlowySvg(
                view.layout.icon,
                size: Size.square(iconSize + 2.0),
              ),
        const HSpace(2),
        FlowyText(
          view.name,
          decoration: TextDecoration.underline,
          fontSize: textStyle?.fontSize,
          fontWeight: textStyle?.fontWeight,
          lineHeight: textStyle?.height,
        ),
        const HSpace(4),
      ],
    );
  }
}

class _NoAccessMentionPageBlock extends StatelessWidget {
  const _NoAccessMentionPageBlock({
    required this.textStyle,
  });

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

class _MobileMentionPageBlock extends StatelessWidget {
  const _MobileMentionPageBlock({
    required this.view,
    required this.textStyle,
    required this.handleTap,
    required this.handleDoubleTap,
  });

  final TextStyle? textStyle;
  final ViewPB view;
  final VoidCallback handleTap;
  final VoidCallback handleDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      onDoubleTap: handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: _MentionPageBlockContent(
        view: view,
        textStyle: textStyle,
      ),
    );
  }
}

class _DesktopMentionPageBlock extends StatelessWidget {
  const _DesktopMentionPageBlock({
    required this.view,
    required this.textStyle,
    required this.handleTap,
  });

  final TextStyle? textStyle;
  final ViewPB view;
  final VoidCallback handleTap;

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
            textStyle: textStyle,
          ),
        ),
      ),
    );
  }
}

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show EditorState, SelectionUpdateReason;
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

final pageMemorizer = <String, ViewPB?>{};

class MentionPageBlock extends StatefulWidget {
  const MentionPageBlock({
    super.key,
    required this.pageId,
    required this.textStyle,
  });

  final String pageId;
  final TextStyle? textStyle;

  @override
  State<MentionPageBlock> createState() => _MentionPageBlockState();
}

class _MentionPageBlockState extends State<MentionPageBlock> {
  late final EditorState editorState;
  late Future<ViewPB?> viewPBFuture;
  ViewListener? viewListener;

  @override
  void initState() {
    super.initState();

    editorState = context.read<EditorState>();
    viewPBFuture = fetchView(widget.pageId);
    viewListener = ViewListener(viewId: widget.pageId)
      ..start(
        onViewUpdated: (p0) {
          pageMemorizer[p0.id] = p0;
          viewPBFuture = fetchView(widget.pageId);
          editorState.reload();
        },
      );
  }

  @override
  void dispose() {
    viewListener?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ViewPB?>(
      initialData: pageMemorizer[widget.pageId],
      future: viewPBFuture,
      builder: (context, state) {
        final view = state.data;
        // memorize the result
        pageMemorizer[widget.pageId] = view;
        if (view == null) {
          return const SizedBox.shrink();
        }
        updateSelection();
        final iconSize = widget.textStyle?.fontSize ?? 16.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FlowyHover(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => openPage(widget.pageId),
              behavior: HitTestBehavior.translucent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HSpace(4),
                  FlowySvg(
                    view.layout.icon,
                    size: Size.square(iconSize + 2.0),
                  ),
                  const HSpace(2),
                  FlowyText(
                    view.name,
                    decoration: TextDecoration.underline,
                    fontSize: widget.textStyle?.fontSize,
                    fontWeight: widget.textStyle?.fontWeight,
                  ),
                  const HSpace(2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void openPage(String pageId) async {
    final view = await fetchView(pageId);
    if (view == null) {
      Log.error('Page($pageId) not found');
      return;
    }
    getIt<TabsBloc>().add(
      TabsEvent.openPlugin(
        plugin: view.plugin(),
        view: view,
      ),
    );
  }

  Future<ViewPB?> fetchView(String pageId) async {
    final view = await ViewBackendService.getView(pageId).then(
      (value) => value.swap().toOption().toNullable(),
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
        reason: SelectionUpdateReason.transaction,
      );
    });
  }
}

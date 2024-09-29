import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:provider/provider.dart';

Node subPageNode({String? viewId}) {
  return Node(
    type: SubPageBlockKeys.type,
    attributes: {SubPageBlockKeys.viewId: viewId},
  );
}

class SubPageBlockKeys {
  const SubPageBlockKeys._();

  static const String type = 'sub_page';

  /// The ID of the View which is being linked to.
  ///
  static const String viewId = "view_id";

  /// Signifies whether the block was inserted after a Copy operation.
  ///
  static const String wasCopied = "was_copied";

  /// Signifies whether the block was inserted after a Cut operation.
  ///
  static const String wasCut = "was_cut";
}

class SubPageBlockComponentBuilder extends BlockComponentBuilder {
  SubPageBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return SubPageBlockComponent(
      key: node.key,
      node: node,
      showActions: showActions(node),
      configuration: configuration,
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
    );
  }

  @override
  bool validate(Node node) => node.delta == null && node.children.isEmpty;
}

class SubPageBlockComponent extends BlockComponentStatefulWidget {
  const SubPageBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<SubPageBlockComponent> createState() => SubPageBlockComponentState();
}

class SubPageBlockComponentState extends State<SubPageBlockComponent>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  final subPageKey = GlobalKey();

  ViewListener? viewListener;
  Future<ViewPB?>? viewFuture;

  bool isHovering = false;
  bool isHandlingPaste = false;

  bool isInTrash = false;

  EditorState get editorState => context.read<EditorState>();

  @override
  void initState() {
    super.initState();
    final viewId = node.attributes[SubPageBlockKeys.viewId];
    if (viewId != null) {
      _handleCopyCutPaste(viewId);
      viewFuture = fetchView(viewId);
      viewListener = ViewListener(viewId: viewId)
        ..start(
          onViewUpdated: (view) {
            pageMemorizer[view.id] = view;
            viewFuture = fetchView(viewId);
            editorState.reload();
          },
        );
    }
  }

  @override
  void didUpdateWidget(SubPageBlockComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final viewId = node.attributes[SubPageBlockKeys.viewId];
    if (viewId != null) {
      viewFuture = fetchView(viewId);
      viewListener?.stop();
      viewListener = ViewListener(viewId: viewId)
        ..start(
          onViewUpdated: (view) {
            pageMemorizer[view.id] = view;
            viewFuture = fetchView(viewId);
            editorState.reload();
          },
        );
    }
  }

  Future<void> _handleCopyCutPaste(String viewId) async {
    final wasCopied = node.attributes[SubPageBlockKeys.wasCopied];
    if (wasCopied == true) {
      setState(() => isHandlingPaste = true);

      // Duplicate the view to the child of the current page
      final view = pageMemorizer[viewId] ?? await fetchView(viewId);
      if (view == null || !context.mounted) {
        return;
      }

      // ignore: use_build_context_synchronously
      final currentViewId = context.read<DocumentBloc>().documentId;

      final result = await ViewBackendService.duplicate(
        view: view,
        openAfterDuplicate: false,
        includeChildren: true,
        parentViewId: currentViewId,
        syncAfterDuplicate: true,
      );

      await result.fold(
        (view) async {
          setState(() => isHandlingPaste = false);

          // update this node
          final transaction = editorState.transaction;
          transaction.updateNode(
            node,
            {
              SubPageBlockKeys.viewId: view.id,
              SubPageBlockKeys.wasCopied: false,
              SubPageBlockKeys.wasCut: false,
            },
          );
          await editorState.apply(
            transaction,
            withUpdateSelection: false,
            options: const ApplyOptions(recordUndo: false),
          );

          isInTrash = false;
          viewFuture = Future.value(view);
        },
        (error) {
          Log.error(error);
          showSnapBar(context, 'Failed to duplicate page');
        },
      );
    }

    final wasCut = node.attributes[SubPageBlockKeys.wasCut];
    if (wasCut == true) {
      setState(() => isHandlingPaste = true);

      // Move the view to the child of the current page
      final view = pageMemorizer[viewId] ?? await fetchView(viewId);
      if (view == null || !context.mounted) {
        return;
      }

      // We attempt to restore from Trash
      // In cases of eg. undo/redo, this might be the case
      await TrashService.putback(viewId);

      // ignore: use_build_context_synchronously
      final currentViewId = context.read<DocumentBloc>().documentId;

      final result = await ViewBackendService.moveViewV2(
        viewId: viewId,
        newParentId: currentViewId,
        prevViewId: null,
      );

      await result.fold(
        (_) async {
          setState(() => isHandlingPaste = false);
          // Set wasCut and wasCopied to false
          final transaction = editorState.transaction
            ..updateNode(
              node,
              {
                ...node.attributes,
                SubPageBlockKeys.wasCut: false,
                SubPageBlockKeys.wasCopied: false,
              },
            );

          await editorState.apply(
            transaction,
            withUpdateSelection: false,
            options: const ApplyOptions(recordUndo: false),
          );

          isInTrash = false;
          viewFuture = Future.value(view);
        },
        (error) {
          Log.error(error);
          showSnapBar(context, 'Failed to move page');
        },
      );
    }
  }

  @override
  void dispose() {
    viewListener?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ViewPB?>(
      initialData: pageMemorizer[node.attributes[SubPageBlockKeys.viewId]],
      future: viewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        final view = snapshot.data;
        if (view == null) {
          // Delete this node if the view is not found
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final transaction = editorState.transaction..deleteNode(node);
            editorState.apply(
              transaction,
              withUpdateSelection: false,
              options: const ApplyOptions(recordUndo: false),
            );
          });

          return const SizedBox.shrink();
        }

        Widget child = Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => isHovering = true),
            onExit: (_) => setState(() => isHovering = false),
            opaque: false,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: BlockSelectionContainer(
                node: node,
                delegate: this,
                listenable: editorState.selectionNotifier,
                remoteSelection: editorState.remoteSelections,
                blockColor: editorState.editorStyle.selectionColor,
                cursorColor: editorState.editorStyle.cursorColor,
                selectionColor: editorState.editorStyle.selectionColor,
                supportTypes: const [
                  BlockSelectionType.block,
                  BlockSelectionType.cursor,
                  BlockSelectionType.selection,
                ],
                child: GestureDetector(
                  // TODO(Mathias): Handle mobile tap
                  onTap: isHandlingPaste
                      ? null
                      : () => getIt<TabsBloc>().add(
                            TabsEvent.openPlugin(
                              plugin: view.plugin(),
                              view: view,
                            ),
                          ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isHovering
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          const HSpace(10),
                          view.icon.value.isNotEmpty
                              ? FlowyText.emoji(
                                  view.icon.value,
                                  fontSize: textStyle.fontSize,
                                  lineHeight: textStyle.height,
                                )
                              : Opacity(
                                  opacity: 0.6,
                                  child: view.defaultIcon(),
                                ),
                          const HSpace(10),
                          FlowyText(
                            view.name,
                            fontSize: textStyle.fontSize,
                            fontWeight: textStyle.fontWeight,
                            lineHeight: textStyle.height,
                          ),
                          if (isInTrash) ...[
                            const HSpace(4),
                            FlowyText(
                              ' – (in Trash)',
                              fontSize: textStyle.fontSize,
                              fontWeight: textStyle.fontWeight,
                              lineHeight: textStyle.height,
                              color: Theme.of(context).hintColor,
                            ),
                          ] else if (isHandlingPaste) ...[
                            FlowyText(
                              ' – Handling document paste',
                              fontSize: textStyle.fontSize,
                              fontWeight: textStyle.fontWeight,
                              lineHeight: textStyle.height,
                              color: Theme.of(context).hintColor,
                            ),
                            const HSpace(10),
                            const CircularProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        if (widget.showActions && widget.actionBuilder != null) {
          child = BlockComponentActionWrapper(
            node: node,
            actionBuilder: widget.actionBuilder!,
            child: child,
          );
        }

        return child;
      },
    );
  }

  Future<ViewPB?> fetchView(String pageId) async {
    final view = await ViewBackendService.getView(pageId).then(
      (res) => res.toNullable(),
    );

    if (view == null) {
      // try to fetch from trash
      final trashViews = await TrashService().readTrash();
      final trash = trashViews.fold(
        (l) => l.items.firstWhereOrNull((trash) => trash.id == pageId),
        (r) => null,
      );
      if (trash != null) {
        isInTrash = true;
        return ViewPB()
          ..id = trash.id
          ..name = trash.name;
      }
    }

    return view;
  }

  @override
  Position start() => Position(path: widget.node.path);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    return getRectsInSelection(Selection.invalid()).first;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final rects = getRectsInSelection(
      Selection.collapsed(position),
      shiftWithBaseOffset: shiftWithBaseOffset,
    );
    return rects.firstOrNull;
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return [];
    }
    final parentBox = context.findRenderObject();
    final renderBox = subPageKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && renderBox is RenderBox) {
      return [
        renderBox.localToGlobal(Offset.zero, ancestor: parentBox) &
            renderBox.size,
      ];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) =>
      Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) =>
      _renderBox!.localToGlobal(offset);
}

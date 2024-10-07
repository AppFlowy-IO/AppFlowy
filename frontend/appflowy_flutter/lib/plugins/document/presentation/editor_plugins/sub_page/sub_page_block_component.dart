import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/trash/application/trash_listener.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
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
  TrashListener? trashListener;
  Future<ViewPB?>? viewFuture;

  bool isHovering = false;
  bool isHandlingPaste = false;

  EditorState get editorState => context.read<EditorState>();

  String? parentId;

  @override
  void initState() {
    super.initState();
    final viewId = node.attributes[SubPageBlockKeys.viewId];
    if (viewId != null) {
      viewFuture = fetchView(viewId);
      viewListener = ViewListener(viewId: viewId)
        ..start(onViewUpdated: onViewUpdated);
      trashListener = TrashListener()..start(trashUpdated: didUpdateTrash);
    }
  }

  @override
  void didUpdateWidget(SubPageBlockComponent oldWidget) {
    final viewId = node.attributes[SubPageBlockKeys.viewId];
    final oldViewId = viewListener?.viewId ??
        oldWidget.node.attributes[SubPageBlockKeys.viewId];
    if (viewId != null && (viewId != oldViewId || viewListener == null)) {
      viewFuture = fetchView(viewId);
      viewListener?.stop();
      viewListener = ViewListener(viewId: viewId)
        ..start(onViewUpdated: onViewUpdated);
    }
    super.didUpdateWidget(oldWidget);
  }

  void didUpdateTrash(FlowyResult<List<TrashPB>, FlowyError> trashOrFailed) {
    final trashList = trashOrFailed.toNullable();
    if (trashList == null) {
      return;
    }

    final viewId = node.attributes[SubPageBlockKeys.viewId];
    if (trashList.any((t) => t.id == viewId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final transaction = editorState.transaction..deleteNode(node);
          editorState.apply(
            transaction,
            withUpdateSelection: false,
            options: const ApplyOptions(recordUndo: false),
          );
        }
      });
    }
  }

  void onViewUpdated(ViewPB view) {
    pageMemorizer[view.id] = view;
    viewFuture = Future<ViewPB>.value(view);
    editorState.reload();

    if (parentId != view.parentViewId && parentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final transaction = editorState.transaction..deleteNode(node);
          editorState.apply(
            transaction,
            withUpdateSelection: false,
            options: const ApplyOptions(recordUndo: false),
          );
        }
      });
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final transaction = editorState.transaction..deleteNode(node);
              editorState.apply(
                transaction,
                withUpdateSelection: false,
                options: const ApplyOptions(recordUndo: false),
              );
            }
          });

          return const SizedBox.shrink();
        }

        Widget child = Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
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
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SizedBox(
                      height: 32,
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
                          Flexible(
                            child: FlowyText(
                              view.name.trim().isEmpty
                                  ? LocaleKeys.menuAppHeader_defaultNewPageName
                                      .tr()
                                  : view.name,
                              fontSize: textStyle.fontSize,
                              fontWeight: textStyle.fontWeight,
                              lineHeight: textStyle.height,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHandlingPaste) ...[
                            FlowyText(
                              LocaleKeys
                                  .document_plugins_subPage_handlingPasteHint
                                  .tr(),
                              fontSize: textStyle.fontSize,
                              fontWeight: textStyle.fontWeight,
                              lineHeight: textStyle.height,
                              color: Theme.of(context).hintColor,
                            ),
                            const HSpace(10),
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            ),
                          ],
                          const HSpace(10),
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final transaction = editorState.transaction..deleteNode(node);
          editorState.apply(
            transaction,
            withUpdateSelection: false,
            options: const ApplyOptions(recordUndo: false),
          );
        }
      });
    }

    parentId = view?.parentViewId;
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

import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_drop_manager.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:provider/provider.dart';
import 'package:string_validator/string_validator.dart';

import 'file_block_menu.dart';
import 'file_upload_menu.dart';

class FileBlockKeys {
  const FileBlockKeys._();

  static const String type = 'file';

  /// The src of the file.
  ///
  /// The value is a String.
  /// It can be a url for a network file or a local file path.
  ///
  static const String url = 'url';

  /// The name of the file.
  ///
  /// The value is a String.
  ///
  static const String name = 'name';

  /// The type of the url.
  ///
  /// The value is a FileUrlType enum.
  ///
  static const String urlType = 'url_type';

  /// The date of the file upload.
  ///
  /// The value is a timestamp in ms.
  ///
  static const String uploadedAt = 'uploaded_at';

  /// The user who uploaded the file.
  ///
  /// The value is a String, in form of user id.
  ///
  static const String uploadedBy = 'uploaded_by';
}

enum FileUrlType {
  local,
  network,
  cloud;

  static FileUrlType fromIntValue(int value) {
    switch (value) {
      case 0:
        return FileUrlType.local;
      case 1:
        return FileUrlType.network;
      case 2:
        return FileUrlType.cloud;
      default:
        throw UnimplementedError();
    }
  }

  int toIntValue() {
    switch (this) {
      case FileUrlType.local:
        return 0;
      case FileUrlType.network:
        return 1;
      case FileUrlType.cloud:
        return 2;
    }
  }
}

Node fileNode({
  required String url,
  FileUrlType type = FileUrlType.local,
  String? name,
}) {
  return Node(
    type: FileBlockKeys.type,
    attributes: {
      FileBlockKeys.url: url,
      FileBlockKeys.urlType: type.toIntValue(),
      FileBlockKeys.name: name,
      FileBlockKeys.uploadedAt: DateTime.now().millisecondsSinceEpoch,
    },
  );
}

class FileBlockComponentBuilder extends BlockComponentBuilder {
  FileBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return FileBlockComponent(
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

class FileBlockComponent extends BlockComponentStatefulWidget {
  const FileBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<FileBlockComponent> createState() => FileBlockComponentState();
}

class FileBlockComponentState extends State<FileBlockComponent>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  late EditorDropManagerState dropManagerState =
      context.read<EditorDropManagerState>();

  final fileKey = GlobalKey();
  final showActionsNotifier = ValueNotifier<bool>(false);
  final controller = PopoverController();
  final menuController = PopoverController();

  late final editorState = Provider.of<EditorState>(context, listen: false);

  bool alwaysShowMenu = false;
  bool isDragging = false;
  bool isHovering = false;

  @override
  void didChangeDependencies() {
    dropManagerState = context.read<EditorDropManagerState>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final url = node.attributes[FileBlockKeys.url];

    Widget child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => isHovering = true);
        showActionsNotifier.value = true;
      },
      onExit: (_) {
        setState(() => isHovering = false);
        if (!alwaysShowMenu) {
          showActionsNotifier.value = false;
        }
      },
      opaque: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: url != null && url.isNotEmpty
            ? () => afLaunchUrlString(url)
            : () {
                controller.show();
                dropManagerState.add(FileBlockKeys.type);
              },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isHovering
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: isDragging
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const HSpace(10),
                const Icon(Icons.upload_file_outlined),
                const HSpace(10),
                ..._buildTrailing(context),
              ],
            ),
          ),
        ),
      ),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      if (url == null || url.isEmpty) {
        child = DropTarget(
          onDragEntered: (_) {
            if (dropManagerState.isDropEnabled) {
              setState(() => isDragging = true);
            }
          },
          onDragExited: (_) {
            if (dropManagerState.isDropEnabled) {
              setState(() => isDragging = false);
            }
          },
          onDragDone: (details) {
            if (dropManagerState.isDropEnabled) {
              insertFileFromLocal(details.files.first.path);
            }
          },
          child: AppFlowyPopover(
            controller: controller,
            direction: PopoverDirection.bottomWithCenterAligned,
            constraints: const BoxConstraints(
              maxWidth: 480,
              maxHeight: 340,
              minHeight: 80,
            ),
            clickHandler: PopoverClickHandler.gestureDetector,
            onOpen: () => dropManagerState.add(FileBlockKeys.type),
            onClose: () => dropManagerState.remove(FileBlockKeys.type),
            popupBuilder: (_) => FileUploadMenu(
              onInsertLocalFile: insertFileFromLocal,
              onInsertNetworkFile: insertNetworkFile,
            ),
            child: child,
          ),
        );
      }

      child = BlockSelectionContainer(
        node: node,
        delegate: this,
        listenable: editorState.selectionNotifier,
        blockColor: editorState.editorStyle.selectionColor,
        supportTypes: const [BlockSelectionType.block],
        child: Padding(key: fileKey, padding: padding, child: child),
      );
    } else {
      child = Padding(key: fileKey, padding: padding, child: child);
    }

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    if (!PlatformExtension.isDesktopOrWeb) {
      // show a fixed menu on mobile
      child = MobileBlockActionButtons(
        showThreeDots: false,
        node: node,
        editorState: editorState,
        child: child,
      );
    }

    return child;
  }

  List<Widget> _buildTrailing(BuildContext context) {
    if (node.attributes[FileBlockKeys.url]?.isNotEmpty == true) {
      final name = node.attributes[FileBlockKeys.name] as String;
      return [
        Expanded(
          child: FlowyText(
            name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const HSpace(8),
        if (PlatformExtension.isDesktopOrWeb) ...[
          ValueListenableBuilder<bool>(
            valueListenable: showActionsNotifier,
            builder: (_, value, __) {
              final url = node.attributes[FileBlockKeys.url];
              if (!value || url == null || url.isEmpty) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: menuController.show,
                child: AppFlowyPopover(
                  controller: menuController,
                  triggerActions: PopoverTriggerFlags.none,
                  direction: PopoverDirection.bottomWithRightAligned,
                  onClose: () {
                    setState(
                      () {
                        alwaysShowMenu = false;
                        showActionsNotifier.value = false;
                      },
                    );
                  },
                  popupBuilder: (_) {
                    alwaysShowMenu = true;
                    return FileBlockMenu(
                      controller: menuController,
                      node: node,
                      editorState: editorState,
                    );
                  },
                  child: const FileMenuTrigger(),
                ),
              );
            },
          ),
          const HSpace(8),
        ],
      ];
    } else {
      return [
        Flexible(
          child: FlowyText(
            isDragging
                ? LocaleKeys.document_plugins_file_placeholderDragging.tr()
                : LocaleKeys.document_plugins_file_placeholderText.tr(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ];
    }
  }

  Future<void> insertFileFromLocal(String path) async {
    final documentBloc = context.read<DocumentBloc>();
    final isLocalMode = documentBloc.isLocalMode;
    final urlType = isLocalMode ? FileUrlType.local : FileUrlType.cloud;

    String? url;
    String? errorMsg;
    if (isLocalMode) {
      url = await saveFileToLocalStorage(path);
    } else {
      final result =
          await saveFileToCloudStorage(path, documentBloc.documentId);
      url = result.$1;
      errorMsg = result.$2;
    }

    if (errorMsg != null && mounted) {
      return showSnackBarMessage(context, errorMsg);
    }

    // Remove the file block from the drop state manager
    dropManagerState.remove(FileBlockKeys.type);

    final name = Uri.tryParse(path)?.pathSegments.last ?? url;
    final transaction = editorState.transaction;
    transaction.updateNode(widget.node, {
      FileBlockKeys.url: url,
      FileBlockKeys.urlType: urlType.toIntValue(),
      FileBlockKeys.name: name,
      FileBlockKeys.uploadedAt: DateTime.now().millisecondsSinceEpoch,
    });
    await editorState.apply(transaction);
  }

  Future<void> insertNetworkFile(String url) async {
    if (url.isEmpty || !isURL(url)) {
      // show error
      return showSnackBarMessage(
        context,
        LocaleKeys.document_plugins_file_networkUrlInvalid.tr(),
      );
    }

    // Remove the file block from the drop state manager
    dropManagerState.remove(FileBlockKeys.type);

    final name = Uri.tryParse(url)?.pathSegments.last ?? url;
    final transaction = editorState.transaction;
    transaction.updateNode(widget.node, {
      FileBlockKeys.url: url,
      FileBlockKeys.urlType: FileUrlType.network.toIntValue(),
      FileBlockKeys.name: name,
      FileBlockKeys.uploadedAt: DateTime.now().millisecondsSinceEpoch,
    });
    await editorState.apply(transaction);
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
  Rect getBlockRect({bool shiftWithBaseOffset = false}) {
    final renderBox = fileKey.currentContext?.findRenderObject();
    if (renderBox is RenderBox) {
      return Offset.zero & renderBox.size;
    }
    return Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final rects = getRectsInSelection(Selection.collapsed(position));
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
    final renderBox = fileKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && renderBox is RenderBox) {
      return [
        renderBox.localToGlobal(Offset.zero, ancestor: parentBox) &
            renderBox.size,
      ];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  }) =>
      _renderBox!.localToGlobal(offset);
}

@visibleForTesting
class FileMenuTrigger extends StatelessWidget {
  const FileMenuTrigger({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlowyHover(
      resetHoverOnRebuild: false,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: FlowySvg(
          FlowySvgs.three_dots_s,
        ),
      ),
    );
  }
}

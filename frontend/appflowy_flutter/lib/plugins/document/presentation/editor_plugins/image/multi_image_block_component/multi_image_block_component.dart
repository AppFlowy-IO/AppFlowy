import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/layouts/multi_image_layouts.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_placeholder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

const kMultiImagePlaceholderKey = 'multiImagePlaceholderKey';

Node multiImageNode() => Node(
      type: MultiImageBlockKeys.type,
      attributes: {
        MultiImageBlockKeys.images: MultiImageData(images: []).toJson(),
        MultiImageBlockKeys.layout: MultiImageLayout.browser.toIntValue(),
      },
    );

class MultiImageBlockKeys {
  const MultiImageBlockKeys._();

  static const String type = 'multi_image';

  /// The image data for the block, stored as a JSON encoded list of [ImageBlockData].
  ///
  static const String images = 'images';

  /// The layout of the images.
  ///
  /// The value is a MultiImageLayout enum.
  ///
  static const String layout = 'layout';
}

typedef MultiImageBlockComponentMenuBuilder = Widget Function(
  Node node,
  MultiImageBlockComponentState state,
  ValueNotifier<int> indexNotifier,
  VoidCallback onImageDeleted,
);

class MultiImageBlockComponentBuilder extends BlockComponentBuilder {
  MultiImageBlockComponentBuilder({
    super.configuration,
    this.showMenu = false,
    this.menuBuilder,
  });

  final bool showMenu;
  final MultiImageBlockComponentMenuBuilder? menuBuilder;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return MultiImageBlockComponent(
      key: node.key,
      node: node,
      showActions: showActions(node),
      configuration: configuration,
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
      showMenu: showMenu,
      menuBuilder: menuBuilder,
    );
  }

  @override
  bool validate(Node node) => node.delta == null && node.children.isEmpty;
}

class MultiImageBlockComponent extends BlockComponentStatefulWidget {
  const MultiImageBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    this.showMenu = false,
    this.menuBuilder,
    super.configuration = const BlockComponentConfiguration(),
    super.actionBuilder,
  });

  final bool showMenu;

  final MultiImageBlockComponentMenuBuilder? menuBuilder;

  @override
  State<MultiImageBlockComponent> createState() =>
      MultiImageBlockComponentState();
}

class MultiImageBlockComponentState extends State<MultiImageBlockComponent>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final multiImageKey = GlobalKey();

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  late final editorState = Provider.of<EditorState>(context, listen: false);

  final showActionsNotifier = ValueNotifier<bool>(false);

  ValueNotifier<int> indexNotifier = ValueNotifier(0);

  bool alwaysShowMenu = false;

  static const _interceptorKey = 'multi-image-block-interceptor';

  late final interceptor = SelectionGestureInterceptor(
    key: _interceptorKey,
    canTap: (details) => _isTapInBounds(details.globalPosition),
    canPanStart: (details) => _isTapInBounds(details.globalPosition),
  );

  @override
  void initState() {
    super.initState();
    editorState.selectionService.registerGestureInterceptor(interceptor);
  }

  @override
  void dispose() {
    editorState.selectionService.unregisterGestureInterceptor(_interceptorKey);
    super.dispose();
  }

  bool _isTapInBounds(Offset offset) {
    if (_renderBox == null) {
      // We shouldn't block any actions if the render box is not available.
      // This has the potential to break taps on the editor completely if we
      // accidentally return false here.
      return true;
    }

    final localPosition = _renderBox!.globalToLocal(offset);
    return !_renderBox!.paintBounds.contains(localPosition);
  }

  @override
  Widget build(BuildContext context) {
    final data = MultiImageData.fromJson(
      node.attributes[MultiImageBlockKeys.images],
    );

    Widget child;
    if (data.images.isEmpty) {
      final multiImagePlaceholderKey =
          node.extraInfos?[kMultiImagePlaceholderKey];

      child = MultiImagePlaceholder(
        key: multiImagePlaceholderKey is GlobalKey
            ? multiImagePlaceholderKey
            : null,
        node: node,
      );
    } else {
      child = ImageLayoutRender(
        node: node,
        images: data.images,
        editorState: editorState,
        indexNotifier: indexNotifier,
        isLocalMode: context.read<DocumentBloc>().isLocalMode,
        onIndexChanged: (index) => setState(() => indexNotifier.value = index),
      );
    }

    if (UniversalPlatform.isDesktopOrWeb) {
      child = BlockSelectionContainer(
        node: node,
        delegate: this,
        listenable: editorState.selectionNotifier,
        blockColor: editorState.editorStyle.selectionColor,
        supportTypes: const [BlockSelectionType.block],
        child: Padding(key: multiImageKey, padding: padding, child: child),
      );
    } else {
      child = Padding(key: multiImageKey, padding: padding, child: child);
    }

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    if (UniversalPlatform.isDesktopOrWeb) {
      if (widget.showMenu && widget.menuBuilder != null) {
        child = MouseRegion(
          onEnter: (_) => showActionsNotifier.value = true,
          onExit: (_) {
            if (!alwaysShowMenu) {
              showActionsNotifier.value = false;
            }
          },
          hitTestBehavior: HitTestBehavior.opaque,
          opaque: false,
          child: ValueListenableBuilder<bool>(
            valueListenable: showActionsNotifier,
            builder: (context, value, child) {
              return Stack(
                children: [
                  BlockSelectionContainer(
                    node: node,
                    delegate: this,
                    listenable: editorState.selectionNotifier,
                    cursorColor: editorState.editorStyle.cursorColor,
                    selectionColor: editorState.editorStyle.selectionColor,
                    child: child!,
                  ),
                  if (value && data.images.isNotEmpty)
                    widget.menuBuilder!(
                      widget.node,
                      this,
                      indexNotifier,
                      () => setState(
                        () => indexNotifier.value = indexNotifier.value > 0
                            ? indexNotifier.value - 1
                            : 0,
                      ),
                    ),
                ],
              );
            },
            child: child,
          ),
        );
      }
    } else {
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
    final imageBox = multiImageKey.currentContext?.findRenderObject();
    if (imageBox is RenderBox) {
      return Offset.zero & imageBox.size;
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
    final imageBox = multiImageKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && imageBox is RenderBox) {
      return [
        imageBox.localToGlobal(Offset.zero, ancestor: parentBox) &
            imageBox.size,
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

/// The data for a multi-image block, primarily used for
/// serializing and deserializing the block's images.
///
class MultiImageData {
  factory MultiImageData.fromJson(List<dynamic> json) {
    final images = json
        .map((e) => ImageBlockData.fromJson(e as Map<String, dynamic>))
        .toList();
    return MultiImageData(images: images);
  }

  MultiImageData({required this.images});

  final List<ImageBlockData> images;

  List<dynamic> toJson() => images.map((e) => e.toJson()).toList();
}

enum MultiImageLayout {
  browser,
  grid;

  int toIntValue() {
    switch (this) {
      case MultiImageLayout.browser:
        return 0;
      case MultiImageLayout.grid:
        return 1;
    }
  }

  static MultiImageLayout fromIntValue(int value) {
    switch (value) {
      case 0:
        return MultiImageLayout.browser;
      case 1:
        return MultiImageLayout.grid;
      default:
        throw UnimplementedError();
    }
  }

  String get label => switch (this) {
        browser => LocaleKeys.document_plugins_photoGallery_browserLayout.tr(),
        grid => LocaleKeys.document_plugins_photoGallery_gridLayout.tr(),
      };

  FlowySvgData get icon => switch (this) {
        browser => FlowySvgs.photo_layout_browser_s,
        grid => FlowySvgs.photo_layout_grid_s,
      };
}

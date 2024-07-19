import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_layouts.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/resizeable_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/unsupport_image_widget.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ResizableImage;
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:string_validator/string_validator.dart';

const kImagePlaceholderKey = 'imagePlaceholderKey';

enum CustomImageType {
  local,
  internal, // the images saved in self-host cloud
  external; // the images linked from network, like unsplash, https://xxx/yyy/zzz.jpg

  static CustomImageType fromIntValue(int value) {
    switch (value) {
      case 0:
        return CustomImageType.local;
      case 1:
        return CustomImageType.internal;
      case 2:
        return CustomImageType.external;
      default:
        throw UnimplementedError();
    }
  }

  int toIntValue() {
    switch (this) {
      case CustomImageType.local:
        return 0;
      case CustomImageType.internal:
        return 1;
      case CustomImageType.external:
        return 2;
    }
  }
}

class ImageBlockData {
  factory ImageBlockData.fromJson(Map<String, dynamic> json) {
    return ImageBlockData(
      url: json['url'] as String,
      type: CustomImageType.fromIntValue(json['type'] as int),
    );
  }

  ImageBlockData({required this.url, required this.type});

  final String url;
  final CustomImageType type;

  bool get isLocal => type == CustomImageType.local;
  bool get isNotInternal => type != CustomImageType.internal;

  Map<String, dynamic> toJson() {
    return {'url': url, 'type': type.toIntValue()};
  }

  ImageProvider toImageProvider() {
    switch (type) {
      case CustomImageType.internal:
      case CustomImageType.external:
        return NetworkImage(url);
      case CustomImageType.local:
        return FileImage(File(url));
    }
  }
}

class CustomImageBlockKeys {
  const CustomImageBlockKeys._();

  static const String type = 'image';

  /// The align data of a image block.
  ///
  /// The value is a String.
  /// left, center, right
  static const String align = 'align';

  /// The image src of a image block.
  ///
  /// The value is a String.
  /// It can be a url or a base64 string(web).
  static const String url = 'url';

  /// The height of a image block.
  ///
  /// The value is a double.
  static const String width = 'width';

  /// The width of a image block.
  ///
  /// The value is a double.
  static const String height = 'height';

  /// The image type of a image block.
  ///
  /// The value is a CustomImageType enum.
  static const String imageType = 'image_type';

  /// This stores information about additional images
  ///
  /// The value is an encoded JSON String, which contains a [List] of
  /// image URLs and their corresponding image types.
  ///
  /// Example:
  /// ```json
  /// [
  ///   {
  ///     "url": "C:\\Users\\mathias\\AppData\\Roaming\\io.appflowy\\AppFlowy\\data_dev\\images\\image1.jpg",
  ///     "type": 1
  ///   },
  ///   {
  ///     "url": "https://appflowy.cloud/123456789/image2.png",
  ///     "type": 2
  ///   },
  ///   {
  ///     "url": "https://images.unsplash.com/photo-123456789-123456789-image3",
  ///     "type": 3
  ///   }
  /// ]
  /// ```
  ///
  static const String additionalImages = 'additional_images';
}

typedef CustomImageBlockComponentMenuBuilder = Widget Function(
  Node node,
  CustomImageBlockComponentState state,
  int selectedIndex,
);

class CustomImageBlockComponentBuilder extends BlockComponentBuilder {
  CustomImageBlockComponentBuilder({
    super.configuration,
    this.showMenu = false,
    this.menuBuilder,
  });

  /// Whether to show the menu of this block component.
  final bool showMenu;

  ///
  final CustomImageBlockComponentMenuBuilder? menuBuilder;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CustomImageBlockComponent(
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

class CustomImageBlockComponent extends BlockComponentStatefulWidget {
  const CustomImageBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.showMenu = false,
    this.menuBuilder,
  });

  /// Whether to show the menu of this block component.
  final bool showMenu;

  final CustomImageBlockComponentMenuBuilder? menuBuilder;

  @override
  State<CustomImageBlockComponent> createState() =>
      CustomImageBlockComponentState();
}

class CustomImageBlockComponentState extends State<CustomImageBlockComponent>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final imageKey = GlobalKey();
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  late final editorState = Provider.of<EditorState>(context, listen: false);

  final showActionsNotifier = ValueNotifier<bool>(false);

  bool alwaysShowMenu = false;

  final List<ImageBlockData> _allImages = [];
  late ImageBlockData _selectedImage;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _populateAllImages();
  }

  @override
  void didUpdateWidget(covariant CustomImageBlockComponent oldWidget) {
    _populateAllImages();
    super.didUpdateWidget(oldWidget);
  }

  void _populateAllImages() {
    _selectedImage = ImageBlockData(
      url: node.attributes[CustomImageBlockKeys.url],
      type: CustomImageType.fromIntValue(
        node.attributes[CustomImageBlockKeys.imageType] ?? 0,
      ),
    );

    _allImages.clear();
    _allImages.add(_selectedImage);
    _allImages.addAll(_getAdditionalImages());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final attributes = node.attributes;
    final src = attributes[CustomImageBlockKeys.url];

    final alignment = AlignmentExtension.fromString(
      attributes[CustomImageBlockKeys.align] ?? 'center',
    );
    final width = attributes[CustomImageBlockKeys.width]?.toDouble() ??
        MediaQuery.of(context).size.width;
    final height = attributes[CustomImageBlockKeys.height]?.toDouble();
    final rawImageType = attributes[CustomImageBlockKeys.imageType] ?? 0;
    final imageType = CustomImageType.fromIntValue(rawImageType);

    final imagePlaceholderKey = node.extraInfos?[kImagePlaceholderKey];
    Widget child;
    if (src.isEmpty) {
      child = ImagePlaceholder(
        key: imagePlaceholderKey is GlobalKey ? imagePlaceholderKey : null,
        node: node,
      );
    } else if (imageType != CustomImageType.internal &&
        !_checkIfURLIsValid(src)) {
      child = const UnsupportedImageWidget();
    } else if (_allImages.length > 1) {
      child = _renderMultiImageLayout();
    } else {
      child = ResizableImage(
        src: src,
        width: width,
        height: height,
        editable: editorState.editable,
        alignment: alignment,
        type: imageType,
        onDoubleTap: () => showDialog(
          context: context,
          builder: (_) => InteractiveImageViewer(
            imageProvider: AFBlockImageProvider(
              images: [ImageBlockData(url: src, type: imageType)],
            ),
          ),
        ),
        onResize: (width) {
          final transaction = editorState.transaction
            ..updateNode(node, {
              CustomImageBlockKeys.width: width,
            });
          editorState.apply(transaction);
        },
      );
    }

    if (PlatformExtension.isDesktopOrWeb) {
      child = BlockSelectionContainer(
        node: node,
        delegate: this,
        listenable: editorState.selectionNotifier,
        blockColor: editorState.editorStyle.selectionColor,
        supportTypes: const [
          BlockSelectionType.block,
        ],
        child: Padding(
          key: imageKey,
          padding: padding,
          child: child,
        ),
      );
    } else {
      child = Padding(
        key: imageKey,
        padding: padding,
        child: child,
      );
    }

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    // show a hover menu on desktop or web
    if (PlatformExtension.isDesktopOrWeb) {
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
              final url = node.attributes[CustomImageBlockKeys.url];
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
                  if (value && url.isNotEmpty == true)
                    widget.menuBuilder!(
                      widget.node,
                      this,
                      _selectedIndex,
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
        extendActionWidgets: _buildExtendActionWidgets(context),
        child: child,
      );
    }

    return child;
  }

  Widget _renderMultiImageLayout() {
    return ImageBrowserLayout(
      node: node,
      editorState: editorState,
      images: _allImages,
      selectedImage: _selectedImage,
      onIndexChanged: (index) => setState(() => _selectedIndex = index),
    );
  }

  // Get additional images from the node
  List<ImageBlockData> _getAdditionalImages() {
    final additionalImages =
        node.attributes[CustomImageBlockKeys.additionalImages];

    if (additionalImages is String) {
      final List<dynamic> decoded = jsonDecode(additionalImages);
      return decoded.map((e) => ImageBlockData.fromJson(e)).toList();
    }

    return [];
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
    final imageBox = imageKey.currentContext?.findRenderObject();
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
    final imageBox = imageKey.currentContext?.findRenderObject();
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

  // only used on mobile platform
  List<Widget> _buildExtendActionWidgets(BuildContext context) {
    final String url = widget.node.attributes[CustomImageBlockKeys.url];
    if (!_checkIfURLIsValid(url)) {
      return [];
    }

    return [
      // disable the copy link button if the image is hosted on appflowy cloud
      // because the url needs the verification token to be accessible
      if (!url.isAppFlowyCloudUrl)
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.editor_copyLink.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.m_field_copy_s,
          ),
          onTap: () async {
            context.pop();
            showSnackBarMessage(
              context,
              LocaleKeys.document_plugins_image_copiedToPasteBoard.tr(),
            );
            await getIt<ClipboardService>().setPlainText(url);
          },
        ),
      FlowyOptionTile.text(
        showTopBorder: false,
        text: LocaleKeys.document_imageBlock_saveImageToGallery.tr(),
        leftIcon: const FlowySvg(
          FlowySvgs.image_placeholder_s,
          size: Size.square(20),
        ),
        onTap: () async {
          context.pop();
          showSnackBarMessage(
            context,
            LocaleKeys.document_plugins_image_copiedToPasteBoard.tr(),
          );
          await getIt<ClipboardService>().setPlainText(url);
        },
      ),
    ];
  }

  bool _checkIfURLIsValid(dynamic url) {
    if (url is! String) {
      return false;
    }

    if (url.isEmpty) {
      return false;
    }

    if (!isURL(url) && !File(url).existsSync()) {
      return false;
    }

    return true;
  }
}

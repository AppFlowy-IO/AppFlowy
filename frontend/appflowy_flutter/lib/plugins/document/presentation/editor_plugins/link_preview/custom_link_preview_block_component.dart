import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';

import 'custom_link_preview.dart';
import 'link_preview_menu.dart';

class CustomLinkPreviewBlockComponentBuilder extends BlockComponentBuilder {
  CustomLinkPreviewBlockComponentBuilder({
    super.configuration,
    this.cache,
  });

  final LinkPreviewDataCacheInterface? cache;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CustomLinkPreviewBlockComponent(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
      cache: cache,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.attributes[LinkPreviewBlockKeys.url]!.isNotEmpty;
}

class CustomLinkPreviewBlockComponent extends BlockComponentStatefulWidget {
  const CustomLinkPreviewBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.cache,
  });

  final LinkPreviewDataCacheInterface? cache;

  @override
  State<CustomLinkPreviewBlockComponent> createState() =>
      CustomLinkPreviewBlockComponentState();
}

class CustomLinkPreviewBlockComponentState
    extends State<CustomLinkPreviewBlockComponent>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  String get url => widget.node.attributes[LinkPreviewBlockKeys.url]!;

  late final LinkPreviewParser parser;
  late Future<void> future;

  final showActionsNotifier = ValueNotifier<bool>(false);
  bool isMenuShowing = false, isHovering = false;

  @override
  void initState() {
    super.initState();
    parser = LinkPreviewParser(url: url, cache: widget.cache);
    future = parser.start();
  }

  @override
  void didUpdateWidget(CustomLinkPreviewBlockComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final url = widget.node.attributes[LinkPreviewBlockKeys.url]!;
    final oldUrl = oldWidget.node.attributes[LinkPreviewBlockKeys.url]!;
    if (url != oldUrl) {
      parser = LinkPreviewParser(url: url, cache: widget.cache);
      setState(() {
        future = parser.start();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        isHovering = true;
        showActionsNotifier.value = true;
      },
      onExit: (_) {
        isHovering = false;
        Future.delayed(const Duration(milliseconds: 200), () {
          if (isMenuShowing || isHovering) return;
          if (mounted) showActionsNotifier.value = false;
        });
      },
      hitTestBehavior: HitTestBehavior.opaque,
      opaque: false,
      child: ValueListenableBuilder<bool>(
        valueListenable: showActionsNotifier,
        builder: (context, showActions, child) {
          return FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              Widget child;

              if (snapshot.connectionState != ConnectionState.done) {
                child = CustomLinkPreviewWidget(
                  node: node,
                  url: url,
                  isHovering: showActions,
                );
              } else {
                final title = parser.getContent(LinkPreviewRegex.title);
                final description =
                    parser.getContent(LinkPreviewRegex.description);
                final image = parser.getContent(LinkPreviewRegex.image);

                if (title == null && description == null && image == null) {
                  child = CustomLinkPreviewWidget(
                    node: node,
                    url: url,
                    isHovering: showActions,
                    status: LinkPreviewStatus.error,
                  );
                } else {
                  child = CustomLinkPreviewWidget(
                    node: node,
                    url: url,
                    title: title,
                    description: description,
                    imageUrl: image,
                    isHovering: showActions,
                    status: LinkPreviewStatus.idle,
                  );
                }
              }

              child = Padding(padding: padding, child: child);

              if (widget.showActions && widget.actionBuilder != null) {
                child = BlockComponentActionWrapper(
                  node: node,
                  actionBuilder: widget.actionBuilder!,
                  child: child,
                );
              }

              child = Stack(
                children: [
                  child,
                  if (showActions)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: CustomLinkPreviewMenu(
                        onMenuShowed: () {
                          isMenuShowing = true;
                        },
                        onMenuHided: () {
                          isMenuShowing = false;
                          if (!isHovering && mounted) {
                            showActionsNotifier.value = false;
                          }
                        },
                        onReload: () {
                          if (mounted) {
                            setState(() {
                              future = parser.start();
                            });
                          }
                        },
                        node: node,
                      ),
                    ),
                ],
              );

              return child;
            },
          );
        },
      ),
    );
  }
}

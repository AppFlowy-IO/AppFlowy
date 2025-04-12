import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_parser.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';

import 'custom_link_preview.dart';
import 'default_selectable_mixin.dart';
import 'link_preview_menu.dart';

class CustomLinkPreviewBlockComponentBuilder extends BlockComponentBuilder {
  CustomLinkPreviewBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    final isEmbed =
        node.attributes[LinkEmbedKeys.previewType] == LinkEmbedKeys.embed;
    if (isEmbed) {
      return LinkEmbedBlockComponent(
        key: node.key,
        node: node,
        configuration: configuration,
        showActions: showActions(node),
        actionBuilder: (_, state) =>
            actionBuilder(blockComponentContext, state),
      );
    }
    return CustomLinkPreviewBlockComponent(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
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
  });

  @override
  DefaultSelectableMixinState<CustomLinkPreviewBlockComponent> createState() =>
      CustomLinkPreviewBlockComponentState();
}

class CustomLinkPreviewBlockComponentState
    extends DefaultSelectableMixinState<CustomLinkPreviewBlockComponent>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  String get url => widget.node.attributes[LinkPreviewBlockKeys.url]!;

  final parser = LinkParser();
  LinkLoadingStatus status = LinkLoadingStatus.loading;
  late LinkInfo linkInfo = LinkInfo(url: url);

  final showActionsNotifier = ValueNotifier<bool>(false);
  bool isMenuShowing = false, isHovering = false;

  @override
  void initState() {
    super.initState();
    parser.addLinkInfoListener((v) {
      final hasNewInfo = !v.isEmpty(), hasOldInfo = !linkInfo.isEmpty();
      if (mounted) {
        setState(() {
          if (hasNewInfo) {
            linkInfo = v;
            status = LinkLoadingStatus.idle;
          } else if (!hasOldInfo) {
            status = LinkLoadingStatus.error;
          }
        });
      }
    });
    parser.start(url);
  }

  @override
  void dispose() {
    parser.dispose();
    super.dispose();
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
      child: ValueListenableBuilder(
        valueListenable: showActionsNotifier,
        builder: (context, showActions, child) {
          return buildPreview(showActions);
        },
      ),
    );
  }

  Widget buildPreview(bool showActions) {
    Widget child = CustomLinkPreviewWidget(
      key: widgetKey,
      node: node,
      url: url,
      isHovering: showActions,
      title: linkInfo.siteName,
      description: linkInfo.description,
      imageUrl: linkInfo.imageUrl,
      status: status,
    );

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
            top: 12,
            right: 12,
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
                setState(() {
                  status = LinkLoadingStatus.loading;
                });
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) parser.start(url);
                });
              },
              node: node,
            ),
          ),
      ],
    );

    final parent = node.parent;
    EdgeInsets newPadding = padding;
    if (parent?.type == CalloutBlockKeys.type) {
      newPadding = padding.copyWith(right: padding.right + 10);
    }
    child = Padding(padding: newPadding, child: child);

    return child;
  }

  @override
  Node get currentNode => node;

  @override
  EdgeInsets get boxPadding => padding;
}

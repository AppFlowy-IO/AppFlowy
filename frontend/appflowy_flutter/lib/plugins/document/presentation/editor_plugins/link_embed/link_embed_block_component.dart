import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/default_selectable_mixin.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'link_embed_menu.dart';

class LinkEmbedKeys {
  const LinkEmbedKeys._();
  static const String previewType = 'preview_type';
  static const String embed = 'embed';
  static const String align = 'align';
}

Node linkEmbedNode({required String url}) => Node(
      type: LinkPreviewBlockKeys.type,
      attributes: {
        LinkPreviewBlockKeys.url: url,
        LinkEmbedKeys.previewType: LinkEmbedKeys.embed,
      },
    );

class LinkEmbedBlockComponent extends BlockComponentStatefulWidget {
  const LinkEmbedBlockComponent({
    super.key,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    required super.node,
  });

  @override
  DefaultSelectableMixinState<LinkEmbedBlockComponent> createState() =>
      LinkEmbedBlockComponentState();
}

class LinkEmbedBlockComponentState
    extends DefaultSelectableMixinState<LinkEmbedBlockComponent>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  String get url => widget.node.attributes[LinkPreviewBlockKeys.url] ?? '';

  LinkLoadingStatus status = LinkLoadingStatus.loading;
  final parser = LinkParser();
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
    Widget result = MouseRegion(
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
      child: buildChild(context),
    );
    final parent = node.parent;
    EdgeInsets newPadding = padding;
    if (parent?.type == CalloutBlockKeys.type) {
      newPadding = padding.copyWith(right: padding.right + 10);
    }

    result = Padding(padding: newPadding, child: result);

    if (widget.showActions && widget.actionBuilder != null) {
      result = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: result,
      );
    }
    return result;
  }

  Widget buildChild(BuildContext context) {
    final theme = AppFlowyTheme.of(context),
        fillSceme = theme.fillColorScheme,
        borderScheme = theme.borderColorScheme;
    Widget child;
    final isIdle = status == LinkLoadingStatus.idle;
    if (isIdle) {
      child = buildContent(context);
    } else {
      child = buildErrorLoadingWidget(context);
    }
    return Container(
      height: 450,
      key: widgetKey,
      decoration: BoxDecoration(
        color: fillSceme.quaternary,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: borderScheme.greyTertiary),
      ),
      child: Stack(
        children: [
          child,
          buildMenu(context),
        ],
      ),
    );
  }

  Widget buildMenu(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: ValueListenableBuilder<bool>(
        valueListenable: showActionsNotifier,
        builder: (context, showActions, child) {
          if (!showActions) return SizedBox.shrink();
          return LinkEmbedMenu(
            editorState: context.read<EditorState>(),
            node: node,
            onReload: () {
              setState(() {
                status = LinkLoadingStatus.loading;
              });
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) parser.start(url);
              });
            },
            onMenuShowed: () {
              isMenuShowing = true;
            },
            onMenuHided: () {
              isMenuShowing = false;
              if (!isHovering && mounted) {
                showActionsNotifier.value = false;
              }
            },
          );
        },
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    final theme = AppFlowyTheme.of(context), textScheme = theme.textColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: FlowyNetworkImage(
              url: linkInfo.imageUrl ?? '',
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                afLaunchUrlString(url, addingHttpSchemeWhenFailed: true),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 40,
                    child: Center(
                      child: linkInfo.buildIconWidget(size: Size.square(32)),
                    ),
                  ),
                  HSpace(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlowyText(
                          linkInfo.siteName ?? '',
                          color: textScheme.primary,
                          fontSize: 14,
                          figmaLineHeight: 20,
                          fontWeight: FontWeight.w600,
                          overflow: TextOverflow.ellipsis,
                        ),
                        VSpace(4),
                        FlowyText.regular(
                          url,
                          color: textScheme.secondary,
                          fontSize: 12,
                          figmaLineHeight: 16,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildErrorLoadingWidget(BuildContext context) {
    final theme = AppFlowyTheme.of(context), textSceme = theme.textColorScheme;
    final isLoading = status == LinkLoadingStatus.loading;
    return isLoading
        ? Center(
            child: SizedBox.square(
              dimension: 64,
              child: CircularProgressIndicator.adaptive(),
            ),
          )
        : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  FlowySvgs.embed_error_xl.path,
                ),
                VSpace(4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$url ',
                          style: TextStyle(
                            color: textSceme.secondary,
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: LocaleKeys
                              .document_plugins_linkPreview_linkPreviewMenu_unableToDisplay
                              .tr(),
                          style: TextStyle(
                            color: textSceme.secondary,
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  @override
  Node get currentNode => node;

  @override
  EdgeInsets get boxPadding => padding;
}

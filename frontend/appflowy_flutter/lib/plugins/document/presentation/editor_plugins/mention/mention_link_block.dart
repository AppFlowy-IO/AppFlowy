import 'dart:async';
import 'dart:math';
import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_hover_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/paste_as/paste_as_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mention_link_error_preview.dart';
import 'mention_link_preview.dart';

class MentionLinkBlock extends StatefulWidget {
  const MentionLinkBlock({
    super.key,
    required this.url,
    required this.editorState,
    required this.node,
    required this.index,
    this.delayToShow = const Duration(milliseconds: 50),
    this.delayToHide = const Duration(milliseconds: 300),
  });

  final String url;
  final Duration delayToShow;
  final Duration delayToHide;
  final EditorState editorState;
  final Node node;
  final int index;

  @override
  State<MentionLinkBlock> createState() => _MentionLinkBlockState();
}

class _MentionLinkBlockState extends State<MentionLinkBlock> {
  final parser = LinkParser();
  _LoadingStatus status = _LoadingStatus.loading;
  final previewController = PopoverController();
  LinkInfo linkInfo = LinkInfo();
  bool isHovering = false;
  int previewFocusNum = 0;
  bool isPreviewHovering = false;
  bool showAtBottom = false;
  final key = GlobalKey();

  bool get isPreviewShowing => previewFocusNum > 0;
  String get url => widget.url;

  EditorState get editorState => widget.editorState;

  Node get node => widget.node;

  int get index => widget.index;

  bool get readyForPreview =>
      status == _LoadingStatus.idle && !linkInfo.isEmpty();

  @override
  void initState() {
    super.initState();

    parser.addLinkInfoListener((v) {
      if (mounted) {
        setState(() {
          if (v.isEmpty() && linkInfo.isEmpty()) {
            status = _LoadingStatus.error;
          } else {
            linkInfo = v;
            status = _LoadingStatus.idle;
          }
        });
      }
    });
    parser.start(url);
  }

  @override
  void dispose() {
    super.dispose();
    parser.dispose();
    previewController.close();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      key: ValueKey(showAtBottom),
      controller: previewController,
      direction: showAtBottom
          ? PopoverDirection.bottomWithLeftAligned
          : PopoverDirection.topWithLeftAligned,
      offset: Offset(0, showAtBottom ? -20 : 20),
      onOpen: () {
        keepEditorFocusNotifier.increase();
        previewFocusNum++;
      },
      onClose: () {
        keepEditorFocusNotifier.decrease();
        previewFocusNum--;
      },
      decorationColor: Colors.transparent,
      popoverDecoration: BoxDecoration(),
      margin: EdgeInsets.zero,
      constraints: getConstraints(),
      borderRadius: BorderRadius.circular(16),
      popupBuilder: (context) => readyForPreview
          ? MentionLinkPreview(
              linkInfo: linkInfo,
              showAtBottom: showAtBottom,
              triggerSize: getSizeFromKey(),
              onEnter: (e) {
                isPreviewHovering = true;
              },
              onExit: (e) {
                isPreviewHovering = false;
                tryToDismissPreview();
              },
              onCopyLink: () => copyLink(context),
              onConvertTo: (s) => convertTo(s),
              onRemoveLink: removeLink,
              onOpenLink: openLink,
            )
          : MentionLinkErrorPreview(
              url: url,
              triggerSize: getSizeFromKey(),
              onEnter: (e) {
                isPreviewHovering = true;
              },
              onExit: (e) {
                isPreviewHovering = false;
                tryToDismissPreview();
              },
              onCopyLink: () => copyLink(context),
              onConvertTo: (s) => convertTo(s),
              onRemoveLink: removeLink,
              onOpenLink: openLink,
            ),
      child: buildIconWithTitle(context),
    );
  }

  Widget buildIconWithTitle(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: onEnter,
      onExit: onExit,
      child: GestureDetector(
        onTap: () async {
          await afLaunchUrlString(url, addingHttpSchemeWhenFailed: true);
        },
        child: FlowyHoverContainer(
          style:
              HoverStyle(hoverColor: Theme.of(context).colorScheme.secondary),
          applyStyle: isHovering,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            key: key,
            children: [
              HSpace(2),
              buildIcon(),
              HSpace(4),
              Flexible(
                child: FlowyText(
                  linkInfo.siteName ?? url,
                  color: theme.textColorScheme.primary,
                  fontSize: 14,
                  figmaLineHeight: 20,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              HSpace(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildIcon() {
    const defaultWidget = FlowySvg(FlowySvgs.toolbar_link_earth_m);
    Widget icon = defaultWidget;
    if (status == _LoadingStatus.loading) {
      icon = Padding(
        padding: const EdgeInsets.all(2.0),
        child: const CircularProgressIndicator(strokeWidth: 1),
      );
    } else {
      icon = linkInfo.buildIconWidget();
    }
    return SizedBox(
      height: 20,
      width: 20,
      child: icon,
    );
  }

  RenderBox? get box => key.currentContext?.findRenderObject() as RenderBox?;

  Size getSizeFromKey() => box?.size ?? Size.zero;

  Future<void> copyLink(BuildContext context) async {
    await context.copyLink(url);
    previewController.close();
  }

  Future<void> openLink() async {
    await afLaunchUrlString(url, addingHttpSchemeWhenFailed: true);
  }

  Future<void> removeLink() async {
    final transaction = editorState.transaction
      ..replaceText(widget.node, widget.index, 1, url, attributes: {});
    await editorState.apply(transaction);
  }

  Future<void> convertTo(PasteMenuType type) async {
    if (type == PasteMenuType.url) {
      await toUrl();
    } else if (type == PasteMenuType.bookmark) {
      await toLinkPreview();
    } else if (type == PasteMenuType.embed) {
      await toLinkPreview(previewType: LinkEmbedKeys.embed);
    }
  }

  Future<void> toUrl() async {
    final transaction = editorState.transaction
      ..replaceText(
        widget.node,
        widget.index,
        1,
        url,
        attributes: {
          AppFlowyRichTextKeys.href: url,
        },
      );
    await editorState.apply(transaction);
  }

  Future<void> toLinkPreview({String? previewType}) async {
    final selection = Selection(
      start: Position(path: node.path, offset: index),
      end: Position(path: node.path, offset: index + 1),
    );
    await convertUrlToLinkPreview(
      editorState,
      selection,
      url,
      previewType: previewType,
    );
  }

  void changeHovering(bool hovering) {
    if (isHovering == hovering) return;
    if (mounted) {
      setState(() {
        isHovering = hovering;
      });
    }
  }

  void changeShowAtBottom(bool bottom) {
    if (showAtBottom == bottom) return;
    if (mounted) {
      setState(() {
        showAtBottom = bottom;
      });
    }
  }

  void tryToDismissPreview() {
    Future.delayed(widget.delayToHide, () {
      if (isHovering || isPreviewHovering) {
        return;
      }
      previewController.close();
    });
  }

  void onEnter(PointerEnterEvent e) {
    changeHovering(true);
    final location = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    if (readyForPreview) {
      if (location.dy < 300) {
        changeShowAtBottom(true);
      } else {
        changeShowAtBottom(false);
      }
    }
    Future.delayed(widget.delayToShow, () {
      if (isHovering && !isPreviewShowing && status != _LoadingStatus.loading) {
        showPreview();
      }
    });
  }

  void onExit(PointerExitEvent e) {
    changeHovering(false);
    tryToDismissPreview();
  }

  void showPreview() {
    if (!mounted) return;
    keepEditorFocusNotifier.increase();
    previewController.show();
    previewFocusNum++;
  }

  BoxConstraints getConstraints() {
    final size = getSizeFromKey();
    if (!readyForPreview) {
      return BoxConstraints(
        maxWidth: max(320, size.width),
        maxHeight: 48 + size.height,
      );
    }
    return BoxConstraints(
      maxWidth: max(300, size.width),
      maxHeight: 300,
    );
  }
}

enum _LoadingStatus {
  loading,
  idle,
  error,
}

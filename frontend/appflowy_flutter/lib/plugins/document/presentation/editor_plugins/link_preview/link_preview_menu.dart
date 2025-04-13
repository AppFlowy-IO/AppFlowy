import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_hover_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_replace_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/menu/menu_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomLinkPreviewMenu extends StatefulWidget {
  const CustomLinkPreviewMenu({
    super.key,
    required this.onMenuShowed,
    required this.onMenuHided,
    required this.onReload,
    required this.node,
  });
  final VoidCallback onMenuShowed;
  final VoidCallback onMenuHided;
  final VoidCallback onReload;
  final Node node;

  @override
  State<CustomLinkPreviewMenu> createState() => _CustomLinkPreviewMenuState();
}

class _CustomLinkPreviewMenuState extends State<CustomLinkPreviewMenu> {
  final popoverController = PopoverController();
  final buttonKey = GlobalKey();
  bool closed = false;
  bool selected = false;

  @override
  void dispose() {
    super.dispose();
    popoverController.close();
    widget.onMenuHided.call();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      offset: Offset(0, 0.0),
      direction: PopoverDirection.bottomWithRightAligned,
      margin: EdgeInsets.zero,
      controller: popoverController,
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () {
        keepEditorFocusNotifier.decrease();
        if (!closed) {
          closed = true;
          return;
        } else {
          closed = false;
          widget.onMenuHided.call();
        }
        setState(() {
          selected = false;
        });
      },
      popupBuilder: (context) => buildMenu(),
      child: FlowyIconButton(
        key: buttonKey,
        isSelected: selected,
        icon: FlowySvg(FlowySvgs.toolbar_more_m),
        onPressed: showPopover,
      ),
    );
  }

  Widget buildMenu() {
    return MouseRegion(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SeparatedColumn(
          mainAxisSize: MainAxisSize.min,
          separatorBuilder: () => const VSpace(0.0),
          children:
              List.generate(LinkPreviewMenuCommand.values.length, (index) {
            final command = LinkPreviewMenuCommand.values[index];
            return SizedBox(
              height: 36,
              child: FlowyButton(
                text: FlowyText(
                  command.title,
                  fontWeight: FontWeight.w400,
                  figmaLineHeight: 20,
                ),
                onTap: () => onTap(command),
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> onTap(LinkPreviewMenuCommand command) async {
    final editorState = context.read<EditorState>();
    final node = widget.node;
    final url = node.attributes[LinkPreviewBlockKeys.url];
    switch (command) {
      case LinkPreviewMenuCommand.convertToMention:
        await convertUrlPreviewNodeToMention(editorState, node);
        break;
      case LinkPreviewMenuCommand.convertToUrl:
        await convertUrlPreviewNodeToLink(editorState, node);
        break;
      case LinkPreviewMenuCommand.convertToEmbed:
        final transaction = editorState.transaction;
        transaction.updateNode(node, {
          LinkPreviewBlockKeys.url: url,
          LinkEmbedKeys.previewType: LinkEmbedKeys.embed,
        });
        await editorState.apply(transaction);
        break;
      case LinkPreviewMenuCommand.copyLink:
        if (url != null) {
          await context.copyLink(url);
        }
        break;
      case LinkPreviewMenuCommand.replace:
        final box = buttonKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        final p = box.localToGlobal(Offset.zero);
        showReplaceMenu(
          context: context,
          editorState: editorState,
          node: node,
          url: url,
          ltrb: LTRB(left: p.dx - 330, top: p.dy),
          onReplace: (url) async {
            await convertLinkBlockToOtherLinkBlock(
              editorState,
              node,
              node.type,
              url: url,
            );
          },
        );
        break;
      case LinkPreviewMenuCommand.reload:
        widget.onReload.call();
        break;
      case LinkPreviewMenuCommand.removeLink:
        await removeUrlPreviewLink(editorState, node);
        break;
    }
    closePopover();
  }

  void showPopover() {
    widget.onMenuShowed.call();
    keepEditorFocusNotifier.increase();
    popoverController.show();
    setState(() {
      selected = true;
    });
  }

  void closePopover() {
    popoverController.close();
    widget.onMenuHided.call();
  }
}

enum LinkPreviewMenuCommand {
  convertToMention,
  convertToUrl,
  convertToEmbed,
  copyLink,
  replace,
  reload,
  removeLink;

  String get title {
    switch (this) {
      case convertToMention:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_toMetion
            .tr();
      case LinkPreviewMenuCommand.convertToUrl:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_toUrl
            .tr();
      case LinkPreviewMenuCommand.convertToEmbed:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_toEmbed
            .tr();
      case LinkPreviewMenuCommand.copyLink:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_copyLink
            .tr();
      case LinkPreviewMenuCommand.replace:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_replace
            .tr();
      case LinkPreviewMenuCommand.reload:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_reload
            .tr();
      case LinkPreviewMenuCommand.removeLink:
        return LocaleKeys
            .document_plugins_linkPreview_linkPreviewMenu_removeLink
            .tr();
    }
  }
}

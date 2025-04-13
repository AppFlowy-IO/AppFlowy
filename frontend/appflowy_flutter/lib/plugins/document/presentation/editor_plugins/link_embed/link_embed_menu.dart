import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_hover_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_replace_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/paste_as/paste_as_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/menu/menu_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';

import 'link_embed_block_component.dart';

class LinkEmbedMenu extends StatefulWidget {
  const LinkEmbedMenu({
    super.key,
    required this.node,
    required this.editorState,
    required this.onMenuShowed,
    required this.onMenuHided,
    required this.onReload,
  });

  final Node node;
  final EditorState editorState;
  final VoidCallback onMenuShowed;
  final VoidCallback onMenuHided;
  final VoidCallback onReload;

  @override
  State<LinkEmbedMenu> createState() => _LinkEmbedMenuState();
}

class _LinkEmbedMenuState extends State<LinkEmbedMenu> {
  final turnintoController = PopoverController();
  final moreOptionController = PopoverController();
  int turnintoMenuNum = 0, moreOptionNum = 0, alignMenuNum = 0;
  final moreOptionButtonKey = GlobalKey();
  bool get isTurnIntoShowing => turnintoMenuNum > 0;
  bool get isMoreOptionShowing => moreOptionNum > 0;
  bool get isAlignMenuShowing => alignMenuNum > 0;

  Node get node => widget.node;
  EditorState get editorState => widget.editorState;

  String get url => node.attributes[LinkPreviewBlockKeys.url] ?? '';

  @override
  void dispose() {
    super.dispose();
    turnintoController.close();
    moreOptionController.close();
    widget.onMenuHided.call();
  }

  @override
  Widget build(BuildContext context) {
    return buildChild();
  }

  Widget buildChild() {
    final theme = AppFlowyTheme.of(context),
        iconScheme = theme.iconColorTheme,
        fillScheme = theme.fillColorScheme;

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: fillScheme.primaryAlpha80,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FlowyIconButton(
          //   icon: FlowySvg(
          //     FlowySvgs.embed_fullscreen_m,
          //     color: iconScheme.tertiary,
          //   ),
          //   tooltipText: LocaleKeys.document_imageBlock_openFullScreen.tr(),
          //   preferBelow: false,
          //   onPressed: () {},
          // ),
          FlowyIconButton(
            icon: FlowySvg(
              FlowySvgs.toolbar_link_m,
              color: iconScheme.tertiary,
            ),
            tooltipText: LocaleKeys.editor_copyLink.tr(),
            preferBelow: false,
            onPressed: () => copyLink(context),
          ),
          buildTurnIntoBotton(),
          buildMoreOptionBotton(),
        ],
      ),
    );
  }

  Widget buildTurnIntoBotton() {
    final theme = AppFlowyTheme.of(context), iconScheme = theme.iconColorTheme;
    return AppFlowyPopover(
      offset: Offset(0, 6),
      direction: PopoverDirection.bottomWithRightAligned,
      margin: EdgeInsets.zero,
      controller: turnintoController,
      onOpen: () {
        keepEditorFocusNotifier.increase();
        turnintoMenuNum++;
      },
      onClose: () {
        keepEditorFocusNotifier.decrease();
        turnintoMenuNum--;
        checkToHideMenu();
      },
      popupBuilder: (context) => buildTurnIntoMenu(),
      child: FlowyIconButton(
        icon: FlowySvg(
          FlowySvgs.turninto_m,
          color: iconScheme.tertiary,
        ),
        tooltipText: LocaleKeys.document_toolbar_turnInto.tr(),
        preferBelow: false,
        onPressed: showTurnIntoMenu,
      ),
    );
  }

  Widget buildTurnIntoMenu() {
    final types =
        PasteMenuType.values.where((e) => e != PasteMenuType.embed).toList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SeparatedColumn(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => const VSpace(0.0),
        children: List.generate(types.length, (index) {
          final command = types[index];
          return SizedBox(
            height: 36,
            child: FlowyButton(
              text: FlowyText(
                command.title,
                fontWeight: FontWeight.w400,
                figmaLineHeight: 20,
              ),
              onTap: () {
                if (command == PasteMenuType.bookmark) {
                  final transaction = editorState.transaction;
                  transaction.updateNode(node, {
                    LinkPreviewBlockKeys.url: url,
                    LinkEmbedKeys.previewType: '',
                  });
                  editorState.apply(transaction);
                } else if (command == PasteMenuType.mention) {
                  convertUrlPreviewNodeToMention(editorState, node);
                } else if (command == PasteMenuType.url) {
                  convertUrlPreviewNodeToLink(editorState, node);
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget buildMoreOptionBotton() {
    final theme = AppFlowyTheme.of(context), iconScheme = theme.iconColorTheme;
    return AppFlowyPopover(
      offset: Offset(0, 6),
      direction: PopoverDirection.bottomWithRightAligned,
      margin: EdgeInsets.zero,
      controller: moreOptionController,
      onOpen: () {
        keepEditorFocusNotifier.increase();
        moreOptionNum++;
      },
      onClose: () {
        keepEditorFocusNotifier.decrease();
        moreOptionNum--;
        checkToHideMenu();
      },
      popupBuilder: (context) => buildMoreOptionMenu(),
      child: FlowyIconButton(
        key: moreOptionButtonKey,
        icon: FlowySvg(
          FlowySvgs.toolbar_more_m,
          color: iconScheme.tertiary,
        ),
        tooltipText: LocaleKeys.document_toolbar_moreOptions.tr(),
        preferBelow: false,
        onPressed: showMoreOptionMenu,
      ),
    );
  }

  Widget buildMoreOptionMenu() {
    final types = LinkEmbedMenuCommand.values;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SeparatedColumn(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => const VSpace(0.0),
        children: List.generate(types.length, (index) {
          final command = types[index];
          return SizedBox(
            height: 36,
            child: FlowyButton(
              text: FlowyText(
                command.title,
                fontWeight: FontWeight.w400,
                figmaLineHeight: 20,
              ),
              onTap: () => onEmbedMenuCommand(command),
            ),
          );
        }),
      ),
    );
  }

  void showTurnIntoMenu() {
    keepEditorFocusNotifier.increase();
    turnintoController.show();
    checkToShowMenu();
    turnintoMenuNum++;
    if (isMoreOptionShowing) closeMoreOptionMenu();
  }

  void closeTurnIntoMenu() {
    turnintoController.close();
    checkToHideMenu();
  }

  void showMoreOptionMenu() {
    keepEditorFocusNotifier.increase();
    moreOptionController.show();
    checkToShowMenu();
    moreOptionNum++;
    if (isTurnIntoShowing) closeTurnIntoMenu();
  }

  void closeMoreOptionMenu() {
    moreOptionController.close();
    checkToHideMenu();
  }

  void checkToHideMenu() {
    Future.delayed(Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (!isAlignMenuShowing && !isMoreOptionShowing && !isTurnIntoShowing) {
        widget.onMenuHided.call();
      }
    });
  }

  void checkToShowMenu() {
    if (!isAlignMenuShowing && !isMoreOptionShowing && !isTurnIntoShowing) {
      widget.onMenuShowed.call();
    }
  }

  Future<void> copyLink(BuildContext context) async {
    await context.copyLink(url);
    widget.onMenuHided.call();
  }

  void onEmbedMenuCommand(LinkEmbedMenuCommand command) {
    switch (command) {
      case LinkEmbedMenuCommand.openLink:
        afLaunchUrlString(url, addingHttpSchemeWhenFailed: true);
        break;
      case LinkEmbedMenuCommand.replace:
        final box = moreOptionButtonKey.currentContext?.findRenderObject()
            as RenderBox?;
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
      case LinkEmbedMenuCommand.reload:
        widget.onReload.call();
        break;
      case LinkEmbedMenuCommand.removeLink:
        removeUrlPreviewLink(editorState, node);
        break;
    }
    closeMoreOptionMenu();
  }
}

enum LinkEmbedMenuCommand {
  openLink,
  replace,
  reload,
  removeLink;

  String get title {
    switch (this) {
      case openLink:
        return LocaleKeys.editor_openLink.tr();
      case replace:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_replace
            .tr();
      case reload:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_reload
            .tr();
      case removeLink:
        return LocaleKeys
            .document_plugins_linkPreview_linkPreviewMenu_removeLink
            .tr();
    }
  }
}

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_create_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_parser.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/paste_as/paste_as_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MentionLinkPreview extends StatefulWidget {
  const MentionLinkPreview({
    super.key,
    required this.linkInfo,
    required this.onEnter,
    required this.onExit,
    required this.onCopyLink,
    required this.onRemoveLink,
    required this.onConvertTo,
    required this.onOpenLink,
    required this.triggerSize,
    required this.showAtBottom,
  });

  final LinkInfo linkInfo;
  final PointerEnterEventListener onEnter;
  final PointerExitEventListener onExit;
  final VoidCallback onCopyLink;
  final VoidCallback onRemoveLink;
  final VoidCallback onOpenLink;
  final ValueChanged<PasteMenuType> onConvertTo;
  final Size triggerSize;
  final bool showAtBottom;

  @override
  State<MentionLinkPreview> createState() => _MentionLinkPreviewState();
}

class _MentionLinkPreviewState extends State<MentionLinkPreview> {
  final menuController = PopoverController();
  bool isSelected = false;

  LinkInfo get linkInfo => widget.linkInfo;

  @override
  void dispose() {
    super.dispose();
    menuController.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context),
        textColorScheme = theme.textColorScheme;
    final imageUrl = linkInfo.imageUrl ?? '',
        description = linkInfo.description ?? '';
    final imageHeight = 120.0;
    final card = MouseRegion(
      onEnter: widget.onEnter,
      onExit: widget.onExit,
      child: Container(
        decoration: buildToolbarLinkDecoration(context, radius: 16),
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: FlowyNetworkImage(
                  url: linkInfo.imageUrl ?? '',
                  width: 280,
                  height: imageHeight,
                ),
              ),
            VSpace(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FlowyText.semibold(
                linkInfo.title ?? linkInfo.siteName ?? '',
                fontSize: 14,
                figmaLineHeight: 20,
                color: textColorScheme.primary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            VSpace(4),
            if (description.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FlowyText(
                  description,
                  fontSize: 12,
                  figmaLineHeight: 16,
                  color: textColorScheme.secondary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              VSpace(36),
            ],
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 28,
              child: Row(
                children: [
                  linkInfo.buildIconWidget(size: Size.square(16)),
                  HSpace(6),
                  Expanded(
                    child: FlowyText(
                      linkInfo.siteName ?? linkInfo.url,
                      fontSize: 12,
                      figmaLineHeight: 16,
                      color: textColorScheme.primary,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  buildMoreOptionButton(),
                ],
              ),
            ),
            VSpace(12),
          ],
        ),
      ),
    );

    final clickPlaceHolder = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: widget.onEnter,
      onExit: widget.onExit,
      child: GestureDetector(
        child: Container(
          height: 20,
          width: widget.triggerSize.width,
          color: Colors.white.withAlpha(1),
        ),
        onTap: () {
          widget.onOpenLink.call();
          closePopover();
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widget.showAtBottom
          ? [clickPlaceHolder, card]
          : [card, clickPlaceHolder],
    );
  }

  Widget buildMoreOptionButton() {
    return AppFlowyPopover(
      controller: menuController,
      direction: PopoverDirection.topWithLeftAligned,
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () => keepEditorFocusNotifier.decrease(),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      popupBuilder: (context) => buildConvertMenu(),
      child: FlowyIconButton(
        width: 28,
        height: 28,
        isSelected: isSelected,
        hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
        icon: FlowySvg(
          FlowySvgs.toolbar_more_m,
          size: Size.square(20),
        ),
        onPressed: () {
          setState(() {
            isSelected = true;
          });
          showPopover();
        },
      ),
    );
  }

  Widget buildConvertMenu() {
    return MouseRegion(
      onEnter: widget.onEnter,
      onExit: widget.onExit,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SeparatedColumn(
          mainAxisSize: MainAxisSize.min,
          separatorBuilder: () => const VSpace(0.0),
          children:
              List.generate(MentionLinktMenuCommand.values.length, (index) {
            final command = MentionLinktMenuCommand.values[index];
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

  void showPopover() {
    keepEditorFocusNotifier.increase();
    menuController.show();
  }

  void closePopover() {
    menuController.close();
  }

  void onTap(MentionLinktMenuCommand command) {
    switch (command) {
      case MentionLinktMenuCommand.toURL:
        widget.onConvertTo(PasteMenuType.url);
        break;
      case MentionLinktMenuCommand.toBookmark:
        widget.onConvertTo(PasteMenuType.bookmark);
        break;
      case MentionLinktMenuCommand.toEmbed:
        widget.onConvertTo(PasteMenuType.embed);
        break;
      case MentionLinktMenuCommand.copyLink:
        widget.onCopyLink();
        break;
      case MentionLinktMenuCommand.removeLink:
        widget.onRemoveLink();
        break;
    }
    closePopover();
  }
}

enum MentionLinktMenuCommand {
  toURL,
  toBookmark,
  toEmbed,
  copyLink,
  removeLink;

  String get title {
    switch (this) {
      case toURL:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_toUrl
            .tr();
      case toBookmark:
        return LocaleKeys
            .document_plugins_linkPreview_linkPreviewMenu_toBookmark
            .tr();
      case toEmbed:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_toEmbed
            .tr();
      case copyLink:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_copyLink
            .tr();
      case removeLink:
        return LocaleKeys
            .document_plugins_linkPreview_linkPreviewMenu_removeLink
            .tr();
    }
  }
}

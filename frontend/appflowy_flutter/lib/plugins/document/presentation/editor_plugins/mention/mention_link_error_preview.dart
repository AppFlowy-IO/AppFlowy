import 'dart:math';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_create_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/paste_as/paste_as_menu.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MentionLinkErrorPreview extends StatefulWidget {
  const MentionLinkErrorPreview({
    super.key,
    required this.url,
    required this.onEnter,
    required this.onExit,
    required this.onCopyLink,
    required this.onRemoveLink,
    required this.onConvertTo,
    required this.onOpenLink,
    required this.triggerSize,
    required this.editable,
  });

  final String url;
  final PointerEnterEventListener onEnter;
  final PointerExitEventListener onExit;
  final VoidCallback onCopyLink;
  final VoidCallback onRemoveLink;
  final VoidCallback onOpenLink;
  final ValueChanged<PasteMenuType> onConvertTo;
  final Size triggerSize;
  final bool editable;

  @override
  State<MentionLinkErrorPreview> createState() =>
      _MentionLinkErrorPreviewState();
}

class _MentionLinkErrorPreviewState extends State<MentionLinkErrorPreview> {
  final menuController = PopoverController();
  bool isConvertButtonSelected = false;

  @override
  void dispose() {
    super.dispose();
    menuController.close();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: widget.onEnter,
          onExit: widget.onExit,
          child: SizedBox(
            width: max(320, widget.triggerSize.width),
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 320,
                height: 48,
                decoration: buildToolbarLinkDecoration(context),
                padding: EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: buildLinkWidget()),
                    Container(
                      height: 20,
                      width: 1,
                      color: Color(0xffE8ECF3)
                          .withAlpha(Theme.of(context).isLightMode ? 255 : 40),
                      margin: EdgeInsets.symmetric(horizontal: 6),
                    ),
                    FlowyIconButton(
                      icon: FlowySvg(FlowySvgs.toolbar_link_m),
                      tooltipText: LocaleKeys.editor_copyLink.tr(),
                      preferBelow: false,
                      width: 36,
                      height: 32,
                      onPressed: widget.onCopyLink,
                    ),
                    buildConvertButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: widget.onEnter,
          onExit: widget.onExit,
          child: GestureDetector(
            onTap: widget.onOpenLink,
            child: Container(
              width: widget.triggerSize.width,
              height: widget.triggerSize.height,
              color: Colors.black.withAlpha(1),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLinkWidget() {
    final url = widget.url;
    return FlowyTooltip(
      message: url,
      preferBelow: false,
      child: FlowyText.regular(
        url,
        overflow: TextOverflow.ellipsis,
        figmaLineHeight: 20,
        fontSize: 14,
      ),
    );
  }

  Widget buildConvertButton() {
    return AppFlowyPopover(
      offset: Offset(8, 10),
      direction: PopoverDirection.bottomWithRightAligned,
      margin: EdgeInsets.zero,
      controller: menuController,
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () => keepEditorFocusNotifier.decrease(),
      popupBuilder: (context) => buildConvertMenu(),
      child: FlowyIconButton(
        icon: FlowySvg(FlowySvgs.turninto_m),
        isSelected: isConvertButtonSelected,
        tooltipText: LocaleKeys.editor_convertTo.tr(),
        preferBelow: false,
        width: 36,
        height: 32,
        onPressed: () {
          setState(() {
            isConvertButtonSelected = true;
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
          children: List.generate(MentionLinktErrorMenuCommand.values.length,
              (index) {
            final command = MentionLinktErrorMenuCommand.values[index];
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

  void onTap(MentionLinktErrorMenuCommand command) {
    switch (command) {
      case MentionLinktErrorMenuCommand.toURL:
        widget.onConvertTo(PasteMenuType.url);
        break;
      case MentionLinktErrorMenuCommand.toBookmark:
        widget.onConvertTo(PasteMenuType.bookmark);
        break;
      case MentionLinktErrorMenuCommand.toEmbed:
        widget.onConvertTo(PasteMenuType.embed);
        break;
      case MentionLinktErrorMenuCommand.removeLink:
        widget.onRemoveLink();
        break;
    }
    closePopover();
  }
}

enum MentionLinktErrorMenuCommand {
  toURL,
  toBookmark,
  toEmbed,
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
      case removeLink:
        return LocaleKeys
            .document_plugins_linkPreview_linkPreviewMenu_removeLink
            .tr();
    }
  }
}

import 'dart:math';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/desktop_floating_toolbar.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/link_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/custom_link_toolbar_item.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import 'link_create_menu.dart';
import 'link_edit_menu.dart';
import 'link_extension.dart';

class LinkHoverTrigger extends StatefulWidget {
  const LinkHoverTrigger({
    super.key,
    required this.editorState,
    required this.selection,
    required this.node,
    required this.attribute,
    required this.size,
    this.delayToShow = const Duration(milliseconds: 50),
    this.delayToHide = const Duration(milliseconds: 300),
  });

  final EditorState editorState;
  final Selection selection;
  final Node node;
  final Attributes attribute;
  final Size size;
  final Duration delayToShow;
  final Duration delayToHide;

  @override
  State<LinkHoverTrigger> createState() => _LinkHoverTriggerState();
}

class _LinkHoverTriggerState extends State<LinkHoverTrigger> {
  final hoverMenuController = PopoverController();
  final editMenuController = PopoverController();
  final toolbarController = getIt<FloatingToolbarController>();
  bool isHoverMenuShowing = false;
  bool isHoverMenuHovering = false;
  bool isHoverTriggerHovering = false;

  Size get size => widget.size;

  EditorState get editorState => widget.editorState;

  Selection get selection => widget.selection;

  Attributes get attribute => widget.attribute;

  late HoverTriggerKey triggerKey = HoverTriggerKey(widget.node.id, selection);

  @override
  void initState() {
    super.initState();
    getIt<LinkHoverTriggers>()._add(triggerKey, showLinkHoverMenu);
    toolbarController.addDisplayListener(onToolbarShow);
  }

  @override
  void dispose() {
    hoverMenuController.close();
    editMenuController.close();
    getIt<LinkHoverTriggers>()._remove(triggerKey, showLinkHoverMenu);
    toolbarController.removeDisplayListener(onToolbarShow);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeHolder = Container(
      color: Colors.black.withAlpha(1),
      width: size.width,
      height: size.height,
    );
    if (UniversalPlatform.isMobile) {
      return GestureDetector(
        onTap: openLink,
        onLongPress: () async {
          await showEditLinkBottomSheet(context, selection, editorState);
        },
        child: placeHolder,
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (v) {
        isHoverTriggerHovering = true;
        Future.delayed(widget.delayToShow, () {
          if (isHoverTriggerHovering && !isHoverMenuShowing) {
            showLinkHoverMenu();
          }
        });
      },
      onExit: (v) {
        isHoverTriggerHovering = false;
        tryToDismissLinkHoverMenu();
      },
      child: buildHoverPopover(buildEditPopover(placeHolder)),
    );
  }

  Widget buildHoverPopover(Widget child) {
    return AppFlowyPopover(
      controller: hoverMenuController,
      direction: PopoverDirection.topWithLeftAligned,
      offset: Offset(0, size.height),
      onOpen: () {
        keepEditorFocusNotifier.increase();
        isHoverMenuShowing = true;
      },
      onClose: () {
        keepEditorFocusNotifier.decrease();
        isHoverMenuShowing = false;
      },
      margin: EdgeInsets.zero,
      constraints: BoxConstraints(
        maxWidth: max(320, size.width),
        maxHeight: 48 + size.height,
      ),
      decorationColor: Colors.transparent,
      popoverDecoration: BoxDecoration(),
      popupBuilder: (context) => LinkHoverMenu(
        attribute: widget.attribute,
        triggerSize: size,
        onEnter: (_) {
          isHoverMenuHovering = true;
        },
        onExit: (_) {
          isHoverMenuHovering = false;
          tryToDismissLinkHoverMenu();
        },
        onConvertTo: (type) => convertLinkTo(editorState, selection, type),
        onOpenLink: openLink,
        onCopyLink: () => copyLink(context),
        onEditLink: showLinkEditMenu,
        onRemoveLink: () => editorState.removeLink(selection),
      ),
      child: child,
    );
  }

  Widget buildEditPopover(Widget child) {
    final href = attribute.href ?? '',
        isPage = attribute.isPage,
        title = editorState.getTextInSelection(selection).join();
    final currentViewId = context.read<DocumentBloc?>()?.documentId ?? '';
    return AppFlowyPopover(
      controller: editMenuController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: Offset(0, 0),
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () => keepEditorFocusNotifier.decrease(),
      margin: EdgeInsets.zero,
      asBarrier: true,
      decorationColor: Colors.transparent,
      popoverDecoration: BoxDecoration(),
      constraints: BoxConstraints(
        maxWidth: 400,
        minHeight: 282,
      ),
      popupBuilder: (context) => LinkEditMenu(
        currentViewId: currentViewId,
        linkInfo: LinkInfo(name: title, link: href, isPage: isPage),
        onDismiss: () => editMenuController.close(),
        onApply: (info) => editorState.applyLink(selection, info),
        onRemoveLink: (linkinfo) =>
            onRemoveAndReplaceLink(editorState, selection, linkinfo.name),
      ),
      child: child,
    );
  }

  void onToolbarShow() => hoverMenuController.close();

  void showLinkHoverMenu() {
    if (UniversalPlatform.isMobile ||
        isHoverMenuShowing ||
        toolbarController.isToolbarShowing ||
        !mounted) {
      return;
    }
    keepEditorFocusNotifier.increase();
    hoverMenuController.show();
  }

  void showLinkEditMenu() {
    if (UniversalPlatform.isMobile) return;
    keepEditorFocusNotifier.increase();
    hoverMenuController.close();
    editMenuController.show();
  }

  void tryToDismissLinkHoverMenu() {
    Future.delayed(widget.delayToHide, () {
      if (isHoverMenuHovering || isHoverTriggerHovering) {
        return;
      }
      hoverMenuController.close();
    });
  }

  Future<void> openLink() async {
    final href = widget.attribute.href ?? '', isPage = widget.attribute.isPage;

    if (isPage) {
      final viewId = href.split('/').lastOrNull ?? '';
      if (viewId.isEmpty) {
        await afLaunchUrlString(href, addingHttpSchemeWhenFailed: true);
      } else {
        final (view, isInTrash, isDeleted) =
            await ViewBackendService.getMentionPageStatus(viewId);
        if (view != null) {
          await handleMentionBlockTap(context, widget.editorState, view);
        }
      }
    } else {
      await afLaunchUrlString(href, addingHttpSchemeWhenFailed: true);
    }
  }

  Future<void> copyLink(BuildContext context) async {
    final href = widget.attribute.href ?? '';
    await context.copyLink(href);
    hoverMenuController.close();
  }

  Future<void> convertLinkTo(
    EditorState editorState,
    Selection selection,
    LinkConvertMenuCommand type,
  ) async {
    final url = widget.attribute.href ?? '';
    if (type == LinkConvertMenuCommand.toBookmark) {
      await convertUrlToLinkPreview(editorState, selection, url);
    } else if (type == LinkConvertMenuCommand.toMention) {
      await convertUrlToMention(editorState, selection);
    } else if (type == LinkConvertMenuCommand.toEmbed) {
      await convertUrlToLinkPreview(
        editorState,
        selection,
        url,
        previewType: LinkEmbedKeys.embed,
      );
    }
  }

  void onRemoveAndReplaceLink(
    EditorState editorState,
    Selection selection,
    String text,
  ) {
    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final index = selection.normalized.startIndex;
    final length = selection.length;
    final transaction = editorState.transaction
      ..replaceText(
        node,
        index,
        length,
        text,
        attributes: {
          BuiltInAttributeKey.href: null,
          kIsPageLink: null,
        },
      );
    editorState.apply(transaction);
  }
}

class LinkHoverMenu extends StatefulWidget {
  const LinkHoverMenu({
    super.key,
    required this.attribute,
    required this.onEnter,
    required this.onExit,
    required this.triggerSize,
    required this.onCopyLink,
    required this.onOpenLink,
    required this.onEditLink,
    required this.onRemoveLink,
    required this.onConvertTo,
  });

  final Attributes attribute;
  final PointerEnterEventListener onEnter;
  final PointerExitEventListener onExit;
  final Size triggerSize;
  final VoidCallback onCopyLink;
  final VoidCallback onOpenLink;
  final VoidCallback onEditLink;
  final VoidCallback onRemoveLink;
  final ValueChanged<LinkConvertMenuCommand> onConvertTo;

  @override
  State<LinkHoverMenu> createState() => _LinkHoverMenuState();
}

class _LinkHoverMenuState extends State<LinkHoverMenu> {
  ViewPB? currentView;
  late bool isPage = widget.attribute.isPage;
  late String href = widget.attribute.href ?? '';
  final popoverController = PopoverController();
  bool isConvertButtonSelected = false;

  @override
  void initState() {
    super.initState();
    if (isPage) getPageView();
  }

  @override
  void dispose() {
    super.dispose();
    popoverController.close();
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
                    FlowyIconButton(
                      icon: FlowySvg(FlowySvgs.toolbar_link_edit_m),
                      tooltipText: LocaleKeys.editor_editLink.tr(),
                      preferBelow: false,
                      width: 36,
                      height: 32,
                      onPressed: widget.onEditLink,
                    ),
                    buildConvertButton(),
                    FlowyIconButton(
                      icon: FlowySvg(FlowySvgs.toolbar_link_unlink_m),
                      tooltipText: LocaleKeys.editor_removeLink.tr(),
                      preferBelow: false,
                      width: 36,
                      height: 32,
                      onPressed: widget.onRemoveLink,
                    ),
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

  Future<void> getPageView() async {
    final viewId = href.split('/').lastOrNull ?? '';
    final (view, isInTrash, isDeleted) =
        await ViewBackendService.getMentionPageStatus(viewId);
    if (mounted) {
      setState(() {
        currentView = view;
      });
    }
  }

  Widget buildLinkWidget() {
    final view = currentView;
    if (isPage && view == null) {
      return SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(),
      );
    }
    String text = '';
    if (isPage && view != null) {
      text = view.name;
      if (text.isEmpty) {
        text = LocaleKeys.document_title_placeholder.tr();
      }
    } else {
      text = href;
    }
    return FlowyTooltip(
      message: text,
      preferBelow: false,
      child: FlowyText.regular(
        text,
        overflow: TextOverflow.ellipsis,
        figmaLineHeight: 20,
        fontSize: 14,
      ),
    );
  }

  Widget buildConvertButton() {
    return AppFlowyPopover(
      offset: Offset(44, 10.0),
      direction: PopoverDirection.bottomWithRightAligned,
      margin: EdgeInsets.zero,
      controller: popoverController,
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
          showConvertMenu();
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
              List.generate(LinkConvertMenuCommand.values.length, (index) {
            final command = LinkConvertMenuCommand.values[index];
            return SizedBox(
              height: 36,
              child: FlowyButton(
                text: FlowyText(
                  command.title,
                  fontWeight: FontWeight.w400,
                  figmaLineHeight: 20,
                ),
                onTap: () {
                  widget.onConvertTo(command);
                  closeConvertMenu();
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  void showConvertMenu() {
    keepEditorFocusNotifier.increase();
    popoverController.show();
  }

  void closeConvertMenu() {
    popoverController.close();
  }
}

class HoverTriggerKey {
  HoverTriggerKey(this.nodeId, this.selection);

  final String nodeId;
  final Selection selection;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HoverTriggerKey &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          isSelectionSame(other.selection);

  bool isSelectionSame(Selection other) =>
      (selection.start == other.start && selection.end == other.end) ||
      (selection.start == other.end && selection.end == other.start);

  @override
  int get hashCode => nodeId.hashCode ^ selection.hashCode;
}

class LinkHoverTriggers {
  final Map<HoverTriggerKey, Set<VoidCallback>> _map = {};

  void _add(HoverTriggerKey key, VoidCallback callback) {
    final callbacks = _map[key] ?? {};
    callbacks.add(callback);
    _map[key] = callbacks;
  }

  void _remove(HoverTriggerKey key, VoidCallback callback) {
    final callbacks = _map[key] ?? {};
    callbacks.remove(callback);
    _map[key] = callbacks;
  }

  void call(HoverTriggerKey key) {
    final callbacks = _map[key] ?? {};
    if (callbacks.isEmpty) return;
    callbacks.first.call();
  }
}

enum LinkConvertMenuCommand {
  toMention,
  toBookmark,
  toEmbed;

  String get title {
    switch (this) {
      case toMention:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_toMetion
            .tr();
      case toBookmark:
        return LocaleKeys
            .document_plugins_linkPreview_linkPreviewMenu_toBookmark
            .tr();
      case toEmbed:
        return LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_toEmbed
            .tr();
    }
  }

  String get type {
    switch (this) {
      case toMention:
        return MentionBlockKeys.type;
      case toBookmark:
        return LinkPreviewBlockKeys.type;
      case toEmbed:
        return LinkPreviewBlockKeys.type;
    }
  }
}

extension LinkExtension on BuildContext {
  Future<void> copyLink(String link) async {
    if (link.isEmpty) return;
    await getIt<ClipboardService>()
        .setData(ClipboardServiceData(plainText: link));
    if (mounted) {
      showToastNotification(
        message: LocaleKeys.shareAction_copyLinkSuccess.tr(),
      );
    }
  }
}

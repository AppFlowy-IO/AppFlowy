import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/paste_as/paste_as_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy/shared/appflowy_network_svg.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:favicon/favicon.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_link_previewer/flutter_link_previewer.dart' hide Size;

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
  LinkInfo? linkInfo;
  bool isHovering = false;
  bool isPreviewShowing = false;
  bool isPreviewHovering = false;
  bool showAtBottom = false;
  final key = GlobalKey();

  String get url => widget.url;

  EditorState get editorState => widget.editorState;

  Node get node => widget.node;

  int get index => widget.index;

  bool get readyForPreview =>
      status == _LoadingStatus.idle && !(linkInfo?.isEmpty() ?? true);

  @override
  void initState() {
    super.initState();

    parser.addLinkInfoListener((v) {
      if (mounted) {
        setState(() {
          linkInfo = v;
          if (v.isEmpty()) {
            status = _LoadingStatus.error;
          } else {
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
      controller: previewController,
      direction: showAtBottom
          ? PopoverDirection.bottomWithLeftAligned
          : PopoverDirection.topWithLeftAligned,
      offset: Offset(0, showAtBottom ? -20 : 20),
      onOpen: () {
        keepEditorFocusNotifier.increase();
        isPreviewShowing = true;
      },
      onClose: () {
        keepEditorFocusNotifier.decrease();
        isPreviewShowing = false;
      },
      decorationColor: Colors.transparent,
      popoverDecoration: BoxDecoration(),
      margin: EdgeInsets.zero,
      constraints: getConstraints(),
      borderRadius: BorderRadius.circular(16),
      popupBuilder: (context) => readyForPreview
          ? MentionLinkPreview(
              linkInfo: linkInfo ?? LinkInfo(),
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
              onOpenLink: () => openLink(),
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
              onOpenLink: () => openLink(),
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
      key: key,
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
            children: [
              HSpace(2),
              buildIcon(),
              HSpace(4),
              Flexible(
                child: FlowyText(
                  linkInfo?.siteName ?? url,
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
    } else if (status == _LoadingStatus.error) {
      icon = defaultWidget;
    } else {
      final faviconUrl = linkInfo?.faviconUrl;
      if (faviconUrl != null) {
        if (faviconUrl.endsWith('.svg')) {
          icon = FlowyNetworkSvg(
            faviconUrl,
            height: 20,
            errorWidget: defaultWidget,
          );
        } else {
          icon = Image.network(
            faviconUrl,
            fit: BoxFit.contain,
            height: 20,
            errorBuilder: (context, error, stackTrace) => defaultWidget,
          );
        }
      }
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
    await getIt<ClipboardService>()
        .setData(ClipboardServiceData(plainText: url));
    if (context.mounted) {
      showToastNotification(
        context,
        message: LocaleKeys.shareAction_copyLinkSuccess.tr(),
      );
    }
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

  Future<void> toLinkPreview() async {
    final selection = Selection(
      start: Position(path: node.path, offset: index),
      end: Position(path: node.path, offset: index + 1),
    );
    await convertUrlToLinkPreview(
      editorState,
      selection,
      url,
    );
    // final transaction = editorState.transaction
    //   ..deleteText(node, index, 1)
    //   ..insertNode(node.path, linkPreviewNode(url: url));
    // await editorState.apply(transaction);
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

  void showPreview() {
    if (isPreviewShowing || !mounted) {
      return;
    }
    keepEditorFocusNotifier.increase();
    previewController.show();
  }

  void onEnter(PointerEnterEvent e) {
    changeHovering(true);
    final location = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    if (readyForPreview) {
      if (location.dy < 280) {
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

class LinkParser {
  static final LinkInfoCache _cache = LinkInfoCache();
  final Set<ValueChanged<LinkInfo>> _listeners = <ValueChanged<LinkInfo>>{};

  Future<void> start(String url) async {
    final data = await _cache.get(url);
    if (data != null) {
      refreshLinkInfo(data);
    }
    await _getLinkInfo(url);
  }

  Future<LinkInfo?> _getLinkInfo(String url) async {
    try {
      final previewData = await getPreviewData(url);
      final favicon = await FaviconFinder.getBest(url);
      final linkInfo = LinkInfo(
        siteName: previewData.title,
        description: previewData.description,
        imageUrl: previewData.image?.url,
        faviconUrl: favicon?.url,
      );
      await _cache.set(url, linkInfo);
      refreshLinkInfo(linkInfo);
      return linkInfo;
    } catch (e, s) {
      Log.error('get link info error: ', e, s);
      return null;
    }
  }

  void refreshLinkInfo(LinkInfo info) {
    for (final listener in _listeners) {
      listener(info);
    }
  }

  void addLinkInfoListener(ValueChanged<LinkInfo> listener) {
    _listeners.add(listener);
  }

  void dispose() {
    _listeners.clear();
  }
}

class LinkInfo {
  factory LinkInfo.fromJson(Map<String, dynamic> json) => LinkInfo(
        siteName: json['siteName'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        faviconUrl: json['faviconUrl'],
      );

  LinkInfo({
    this.siteName,
    this.description,
    this.imageUrl,
    this.faviconUrl,
  });

  final String? siteName;
  final String? description;
  final String? imageUrl;
  final String? faviconUrl;

  Map<String, dynamic> toJson() => {
        'siteName': siteName,
        'description': description,
        'imageUrl': imageUrl,
        'faviconUrl': faviconUrl,
      };

  bool isEmpty() {
    return siteName == null ||
        description == null ||
        imageUrl == null ||
        faviconUrl == null;
  }

  Widget getIconWidget({Size size = const Size.square(20.0)}) {
    if (faviconUrl == null) {
      return FlowySvg(FlowySvgs.toolbar_link_earth_m, size: size);
    }
    if (faviconUrl!.endsWith('.svg')) {
      return FlowyNetworkSvg(
        faviconUrl!,
        height: size.height,
        errorWidget: const FlowySvg(FlowySvgs.toolbar_link_earth_m),
      );
    }
    return Image.network(
      faviconUrl!,
      fit: BoxFit.contain,
      height: size.height,
      errorBuilder: (context, error, stackTrace) =>
          const FlowySvg(FlowySvgs.toolbar_link_earth_m),
    );
  }
}

class LinkInfoCache {
  Future<LinkInfo?> get(String url) async {
    final option = await getIt<KeyValueStorage>().getWithFormat<LinkInfo?>(
      url,
      (value) => LinkInfo.fromJson(jsonDecode(value)),
    );
    return option;
  }

  Future<void> set(String url, LinkInfo data) async {
    await getIt<KeyValueStorage>().set(
      url,
      jsonEncode(data.toJson()),
    );
  }
}

enum _LoadingStatus {
  loading,
  idle,
  error,
}

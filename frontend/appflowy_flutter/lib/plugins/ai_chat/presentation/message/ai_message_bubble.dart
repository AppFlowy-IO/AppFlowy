import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_avatar.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:universal_platform/universal_platform.dart';

import '../layout_define.dart';

class ChatAIMessageBubble extends StatelessWidget {
  const ChatAIMessageBubble({
    super.key,
    required this.message,
    required this.child,
    required this.showActions,
    this.isLastMessage = false,
  });

  final Message message;
  final Widget child;
  final bool showActions;
  final bool isLastMessage;

  @override
  Widget build(BuildContext context) {
    final avatarAndMessage = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ChatAIAvatar(),
        const HSpace(DesktopAIConvoSizes.avatarAndChatBubbleSpacing),
        Expanded(child: child),
      ],
    );

    return showActions
        ? UniversalPlatform.isMobile
            ? _wrapPopMenu(avatarAndMessage)
            : isLastMessage
                ? _wrapBottomActions(avatarAndMessage)
                : _wrapHover(avatarAndMessage)
        : avatarAndMessage;
  }

  Widget _wrapBottomActions(Widget child) {
    return ChatAIBottomInlineActions(
      message: message,
      child: child,
    );
  }

  Widget _wrapHover(Widget child) {
    return ChatAIMessageHover(
      message: message,
      child: child,
    );
  }

  Widget _wrapPopMenu(Widget child) {
    return ChatAIMessagePopup(
      message: message,
      child: child,
    );
  }
}

class ChatAIBottomInlineActions extends StatelessWidget {
  const ChatAIBottomInlineActions({
    super.key,
    required this.child,
    required this.message,
  });

  final Widget child;
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const VSpace(16.0),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: DesktopAIConvoSizes.avatarSize +
                DesktopAIConvoSizes.avatarAndChatBubbleSpacing,
          ),
          child: AIResponseActionBar(
            showDecoration: false,
            children: [
              CopyButton(
                textMessage: message as TextMessage,
              ),
            ],
          ),
        ),
        const VSpace(32.0),
      ],
    );
  }
}

class ChatAIMessageHover extends StatefulWidget {
  const ChatAIMessageHover({
    super.key,
    required this.child,
    required this.message,
  });

  final Widget child;
  final Message message;

  @override
  State<ChatAIMessageHover> createState() => _ChatAIMessageHoverState();
}

class _ChatAIMessageHoverState extends State<ChatAIMessageHover> {
  final controller = OverlayPortalController();
  final layerLink = LayerLink();

  bool hoverBubble = false;
  bool hoverActionBar = false;

  ScrollPosition? scrollPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addScrollListener();
      controller.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onEnter: (_) {
        if (!hoverBubble && isBottomOfWidgetVisible(context)) {
          setState(() => hoverBubble = true);
        }
      },
      onHover: (_) {
        if (!hoverBubble && isBottomOfWidgetVisible(context)) {
          setState(() => hoverBubble = true);
        }
      },
      onExit: (_) {
        if (hoverBubble) {
          setState(() => hoverBubble = false);
        }
      },
      child: OverlayPortal(
        controller: controller,
        overlayChildBuilder: (_) {
          return CompositedTransformFollower(
            showWhenUnlinked: false,
            link: layerLink,
            targetAnchor: Alignment.bottomLeft,
            offset: const Offset(
              DesktopAIConvoSizes.avatarSize +
                  DesktopAIConvoSizes.avatarAndChatBubbleSpacing,
              0,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                opaque: false,
                onEnter: (_) {
                  if (!hoverActionBar && isBottomOfWidgetVisible(context)) {
                    setState(() => hoverActionBar = true);
                  }
                },
                onExit: (_) {
                  if (hoverActionBar) {
                    setState(() => hoverActionBar = false);
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 784,
                    maxHeight: 28,
                  ),
                  alignment: Alignment.topLeft,
                  child: hoverBubble || hoverActionBar
                      ? AIResponseActionBar(
                          showDecoration: true,
                          children: [
                            CopyButton(
                              textMessage: widget.message as TextMessage,
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
          );
        },
        child: CompositedTransformTarget(
          link: layerLink,
          child: widget.child,
        ),
      ),
    );
  }

  void addScrollListener() {
    if (!mounted) {
      return;
    }
    scrollPosition = Scrollable.maybeOf(context)?.position;
    scrollPosition?.addListener(handleScroll);
  }

  void handleScroll() {
    if (!mounted) {
      return;
    }
    if ((hoverActionBar || hoverBubble) && !isBottomOfWidgetVisible(context)) {
      setState(() {
        hoverBubble = false;
        hoverActionBar = false;
      });
    }
  }

  bool isBottomOfWidgetVisible(BuildContext context) {
    if (Scrollable.maybeOf(context) == null) {
      return false;
    }
    final scrollableRenderBox =
        Scrollable.of(context).context.findRenderObject() as RenderBox;
    final scrollableHeight = scrollableRenderBox.size.height;
    final scrollableOffset = scrollableRenderBox.localToGlobal(Offset.zero);

    final messageRenderBox = context.findRenderObject() as RenderBox;
    final messageOffset = messageRenderBox.localToGlobal(Offset.zero);
    final messageHeight = messageRenderBox.size.height;

    return messageOffset.dy + messageHeight + 28 <=
        scrollableOffset.dy + scrollableHeight;
  }

  @override
  void dispose() {
    scrollPosition?.isScrollingNotifier.removeListener(handleScroll);
    super.dispose();
  }
}

class AIResponseActionBar extends StatelessWidget {
  const AIResponseActionBar({
    super.key,
    required this.showDecoration,
    required this.children,
  });

  final List<Widget> children;
  final bool showDecoration;

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;

    final child = SeparatedRow(
      mainAxisSize: MainAxisSize.min,
      separatorBuilder: () =>
          const HSpace(DesktopAIConvoSizes.actionBarIconSpacing),
      children: children,
    );

    return showDecoration
        ? Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              borderRadius: DesktopAIConvoSizes.actionBarIconRadius,
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  spreadRadius: -2,
                  color: isLightMode
                      ? const Color(0x051F2329)
                      : Theme.of(context).shadowColor.withOpacity(0.02),
                ),
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: isLightMode
                      ? const Color(0x051F2329)
                      : Theme.of(context).shadowColor.withOpacity(0.02),
                ),
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 2,
                  color: isLightMode
                      ? const Color(0x051F2329)
                      : Theme.of(context).shadowColor.withOpacity(0.02),
                ),
              ],
            ),
            child: child,
          )
        : child;
  }
}

class CopyButton extends StatelessWidget {
  const CopyButton({
    super.key,
    required this.textMessage,
  });
  final TextMessage textMessage;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.settings_menu_clickToCopy.tr(),
      child: FlowyIconButton(
        width: DesktopAIConvoSizes.actionBarIconSize,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        fillColor: Theme.of(context).cardColor,
        radius: DesktopAIConvoSizes.actionBarIconRadius,
        icon: FlowySvg(
          FlowySvgs.copy_s,
          color: Theme.of(context).hintColor,
          size: const Size.square(16),
        ),
        onPressed: () async {
          final document = customMarkdownToDocument(textMessage.text);
          await getIt<ClipboardService>().setData(
            ClipboardServiceData(
              plainText: textMessage.text,
              inAppJson: jsonEncode(document.toJson()),
            ),
          );
          if (context.mounted) {
            showToastNotification(
              context,
              message: LocaleKeys.grid_url_copiedNotification.tr(),
            );
          }
        },
      ),
    );
  }
}

class ChatAIMessagePopup extends StatelessWidget {
  const ChatAIMessagePopup({
    super.key,
    required this.child,
    required this.message,
  });

  final Widget child;
  final Message message;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        showMobileBottomSheet(
          context,
          showDragHandle: true,
          backgroundColor: AFThemeExtension.of(context).background,
          builder: (bottomSheetContext) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MobileQuickActionButton(
                  onTap: () async {
                    if (message is! TextMessage) {
                      return;
                    }
                    final textMessage = message as TextMessage;
                    final document = customMarkdownToDocument(textMessage.text);
                    await getIt<ClipboardService>().setData(
                      ClipboardServiceData(
                        plainText: textMessage.text,
                        inAppJson: jsonEncode(document.toJson()),
                      ),
                    );
                    if (bottomSheetContext.mounted) {
                      Navigator.of(bottomSheetContext).pop();
                    }
                    if (context.mounted) {
                      showToastNotification(
                        context,
                        message: LocaleKeys.grid_url_copiedNotification.tr(),
                      );
                    }
                  },
                  icon: FlowySvgs.copy_s,
                  iconSize: const Size.square(20),
                  text: LocaleKeys.button_copy.tr(),
                ),
              ],
            );
          },
        );
      },
      child: IgnorePointer(
        child: child,
      ),
    );
  }
}

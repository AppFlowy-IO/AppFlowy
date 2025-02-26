import 'dart:convert';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_edit_document_service.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_message_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

import '../chat_avatar.dart';
import '../layout_define.dart';
import 'ai_message_action_bar.dart';
import 'ai_change_format_bottom_sheet.dart';
import 'message_util.dart';

/// Wraps an AI response message with the avatar and actions. On desktop,
/// the actions will be displayed below the response if the response is the
/// last message in the chat. For the others, the actions will be shown on hover
/// On mobile, the actions will be displayed in a bottom sheet on long press.
class ChatAIMessageBubble extends StatelessWidget {
  const ChatAIMessageBubble({
    super.key,
    required this.message,
    required this.child,
    required this.showActions,
    this.isLastMessage = false,
    this.isSelectingMessages = false,
    this.onRegenerate,
    this.onChangeFormat,
  });

  final Message message;
  final Widget child;
  final bool showActions;
  final bool isLastMessage;
  final bool isSelectingMessages;
  final void Function()? onRegenerate;
  final void Function(PredefinedFormat)? onChangeFormat;

  @override
  Widget build(BuildContext context) {
    final messageWidget = _WrapIsSelectingMessage(
      isSelectingMessages: isSelectingMessages,
      message: message,
      child: child,
    );

    return !isSelectingMessages && showActions
        ? UniversalPlatform.isMobile
            ? _wrapPopMenu(messageWidget)
            : isLastMessage
                ? _wrapBottomActions(messageWidget)
                : _wrapHover(messageWidget)
        : messageWidget;
  }

  Widget _wrapBottomActions(Widget child) {
    return ChatAIBottomInlineActions(
      message: message,
      onRegenerate: onRegenerate,
      onChangeFormat: onChangeFormat,
      child: child,
    );
  }

  Widget _wrapHover(Widget child) {
    return ChatAIMessageHover(
      message: message,
      onRegenerate: onRegenerate,
      onChangeFormat: onChangeFormat,
      child: child,
    );
  }

  Widget _wrapPopMenu(Widget child) {
    return ChatAIMessagePopup(
      message: message,
      onRegenerate: onRegenerate,
      onChangeFormat: onChangeFormat,
      child: child,
    );
  }
}

class ChatAIBottomInlineActions extends StatelessWidget {
  const ChatAIBottomInlineActions({
    super.key,
    required this.child,
    required this.message,
    this.onRegenerate,
    this.onChangeFormat,
  });

  final Widget child;
  final Message message;
  final void Function()? onRegenerate;
  final void Function(PredefinedFormat)? onChangeFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const VSpace(16.0),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: DesktopAIChatSizes.avatarSize +
                DesktopAIChatSizes.avatarAndChatBubbleSpacing,
          ),
          child: AIMessageActionBar(
            message: message,
            showDecoration: false,
            onRegenerate: onRegenerate,
            onChangeFormat: onChangeFormat,
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
    this.onRegenerate,
    this.onChangeFormat,
  });

  final Widget child;
  final Message message;
  final void Function()? onRegenerate;
  final void Function(PredefinedFormat)? onChangeFormat;

  @override
  State<ChatAIMessageHover> createState() => _ChatAIMessageHoverState();
}

class _ChatAIMessageHoverState extends State<ChatAIMessageHover> {
  final controller = OverlayPortalController();
  final layerLink = LayerLink();

  bool hoverBubble = false;
  bool hoverActionBar = false;
  bool overrideVisibility = false;

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
              DesktopAIChatSizes.avatarSize +
                  DesktopAIChatSizes.avatarAndChatBubbleSpacing,
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
                  constraints: BoxConstraints(
                    maxWidth: 784,
                    maxHeight: DesktopAIChatSizes.messageActionBarIconSize +
                        DesktopAIChatSizes
                            .messageHoverActionBarPadding.vertical,
                  ),
                  child: hoverBubble || hoverActionBar || overrideVisibility
                      ? AIMessageActionBar(
                          message: widget.message,
                          showDecoration: true,
                          onRegenerate: widget.onRegenerate,
                          onChangeFormat: widget.onChangeFormat,
                          onOverrideVisibility: (visibility) {
                            overrideVisibility = visibility;
                          },
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

    return messageOffset.dy +
            messageHeight +
            DesktopAIChatSizes.messageActionBarIconSize +
            DesktopAIChatSizes.messageHoverActionBarPadding.vertical <=
        scrollableOffset.dy + scrollableHeight;
  }

  @override
  void dispose() {
    scrollPosition?.isScrollingNotifier.removeListener(handleScroll);
    super.dispose();
  }
}

class ChatAIMessagePopup extends StatelessWidget {
  const ChatAIMessagePopup({
    super.key,
    required this.child,
    required this.message,
    this.onRegenerate,
    this.onChangeFormat,
  });

  final Widget child;
  final Message message;
  final void Function()? onRegenerate;
  final void Function(PredefinedFormat)? onChangeFormat;

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
                _copyButton(context, bottomSheetContext),
                _divider(),
                _regenerateButton(context),
                _divider(),
                _changeFormatButton(context),
                _divider(),
                _saveToPageButton(context),
              ],
            );
          },
        );
      },
      child: child,
    );
  }

  Widget _divider() => const MobileQuickActionDivider();

  Widget _copyButton(BuildContext context, BuildContext bottomSheetContext) {
    return MobileQuickActionButton(
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
    );
  }

  Widget _regenerateButton(BuildContext context) {
    return MobileQuickActionButton(
      onTap: () {
        onRegenerate?.call();
        Navigator.of(context).pop();
      },
      icon: FlowySvgs.ai_try_again_s,
      iconSize: const Size.square(20),
      text: LocaleKeys.chat_regenerate.tr(),
    );
  }

  Widget _changeFormatButton(BuildContext context) {
    return MobileQuickActionButton(
      onTap: () async {
        final result = await showChangeFormatBottomSheet(context);
        if (result != null) {
          onChangeFormat?.call(result);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      icon: FlowySvgs.ai_retry_font_s,
      iconSize: const Size.square(20),
      text: LocaleKeys.chat_changeFormat_actionButton.tr(),
    );
  }

  Widget _saveToPageButton(BuildContext context) {
    return MobileQuickActionButton(
      onTap: () async {
        final selectedView = await showPageSelectorSheet(
          context,
          filter: (view) =>
              !view.isSpace &&
              view.layout.isDocumentView &&
              view.parentViewId != view.id,
        );
        if (selectedView == null) {
          return;
        }

        await ChatEditDocumentService.addMessagesToPage(
          selectedView.id,
          [message as TextMessage],
        );

        if (context.mounted) {
          context.pop();
          openPageFromMessage(context, selectedView);
        }
      },
      icon: FlowySvgs.ai_add_to_page_s,
      iconSize: const Size.square(20),
      text: LocaleKeys.chat_addToPageButton.tr(),
    );
  }
}

class _WrapIsSelectingMessage extends StatelessWidget {
  const _WrapIsSelectingMessage({
    required this.message,
    required this.child,
    this.isSelectingMessages = false,
  });

  final Message message;
  final Widget child;
  final bool isSelectingMessages;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatSelectMessageBloc, ChatSelectMessageState>(
      builder: (context, state) {
        final isSelected =
            context.read<ChatSelectMessageBloc>().isMessageSelected(message.id);
        return GestureDetector(
          onTap: () {
            if (isSelectingMessages) {
              context
                  .read<ChatSelectMessageBloc>()
                  .add(ChatSelectMessageEvent.toggleSelectMessage(message));
            }
          },
          behavior: isSelectingMessages ? HitTestBehavior.opaque : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.tertiaryContainer
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectingMessages)
                  ChatSelectMessageIndicator(isSelected: isSelected)
                else
                  SelectionContainer.disabled(
                    child: const ChatAIAvatar(),
                  ),
                const HSpace(DesktopAIChatSizes.avatarAndChatBubbleSpacing),
                Expanded(
                  child: IgnorePointer(
                    ignoring: isSelectingMessages,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChatSelectMessageIndicator extends StatelessWidget {
  const ChatSelectMessageIndicator({
    super.key,
    required this.isSelected,
  });

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SizedBox.square(
        dimension: 30.0,
        child: Center(
          child: FlowySvg(
            isSelected ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
            blendMode: BlendMode.dst,
            size: const Size.square(20),
          ),
        ),
      ),
    );
  }
}

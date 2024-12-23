import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_edit_document_service.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_sources_cubit.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input/chat_mention_page_bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

import '../chat_avatar.dart';
import '../chat_input/select_sources_menu.dart';
import '../layout_define.dart';

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
    this.onRegenerate,
  });

  final Message message;
  final Widget child;
  final bool showActions;
  final bool isLastMessage;
  final void Function()? onRegenerate;

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
      onRegenerate: onRegenerate,
      child: child,
    );
  }

  Widget _wrapHover(Widget child) {
    return ChatAIMessageHover(
      message: message,
      onRegenerate: onRegenerate,
      child: child,
    );
  }

  Widget _wrapPopMenu(Widget child) {
    return ChatAIMessagePopup(
      message: message,
      onRegenerate: onRegenerate,
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
  });

  final Widget child;
  final Message message;
  final void Function()? onRegenerate;

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
            message: message,
            showDecoration: false,
            onRegenerate: onRegenerate,
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
  });

  final Widget child;
  final Message message;
  final void Function()? onRegenerate;

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
                  constraints: BoxConstraints(
                    maxWidth: 784,
                    maxHeight: DesktopAIConvoSizes.actionBarIconSize +
                        DesktopAIConvoSizes.hoverActionBarPadding.vertical,
                  ),
                  alignment: Alignment.topLeft,
                  child: hoverBubble || hoverActionBar || overrideVisibility
                      ? AIResponseActionBar(
                          message: widget.message,
                          showDecoration: true,
                          onRegenerate: widget.onRegenerate,
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
            DesktopAIConvoSizes.actionBarIconSize +
            DesktopAIConvoSizes.hoverActionBarPadding.vertical <=
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
    required this.message,
    required this.showDecoration,
    this.onRegenerate,
    this.onOverrideVisibility,
  });

  final Message message;
  final bool showDecoration;
  final void Function()? onRegenerate;
  final void Function(bool)? onOverrideVisibility;

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;

    final child = SeparatedRow(
      mainAxisSize: MainAxisSize.min,
      separatorBuilder: () =>
          const HSpace(DesktopAIConvoSizes.actionBarIconSpacing),
      children: _buildChildren(),
    );

    return showDecoration
        ? Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              borderRadius: DesktopAIConvoSizes.hoverActionBarRadius,
              border: Border.all(
                color: isLightMode
                    ? const Color(0x1F1F2329)
                    : Theme.of(context).dividerColor,
              ),
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

  List<Widget> _buildChildren() {
    return [
      CopyButton(
        isInHoverBar: showDecoration,
        textMessage: message as TextMessage,
      ),
      RegenerateButton(
        isInHoverBar: showDecoration,
        onTap: () => onRegenerate?.call(),
      ),
      SaveToPageButton(
        textMessage: message as TextMessage,
        isInHoverBar: showDecoration,
        onOverrideVisibility: onOverrideVisibility,
        onTap: () {},
      ),
    ];
  }
}

class CopyButton extends StatelessWidget {
  const CopyButton({
    super.key,
    required this.isInHoverBar,
    required this.textMessage,
  });

  final bool isInHoverBar;
  final TextMessage textMessage;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.settings_menu_clickToCopy.tr(),
      child: FlowyIconButton(
        width: DesktopAIConvoSizes.actionBarIconSize,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: isInHoverBar
            ? DesktopAIConvoSizes.hoverActionBarIconRadius
            : DesktopAIConvoSizes.actionBarIconRadius,
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

class RegenerateButton extends StatelessWidget {
  const RegenerateButton({
    super.key,
    required this.isInHoverBar,
    required this.onTap,
  });

  final bool isInHoverBar;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.chat_regenerate.tr(),
      child: FlowyIconButton(
        width: DesktopAIConvoSizes.actionBarIconSize,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: isInHoverBar
            ? DesktopAIConvoSizes.hoverActionBarIconRadius
            : DesktopAIConvoSizes.actionBarIconRadius,
        icon: FlowySvg(
          FlowySvgs.ai_undo_s,
          color: Theme.of(context).hintColor,
          size: const Size.square(16),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class SaveToPageButton extends StatefulWidget {
  const SaveToPageButton({
    super.key,
    required this.textMessage,
    required this.isInHoverBar,
    required this.onTap,
    this.onOverrideVisibility,
  });

  final TextMessage textMessage;
  final bool isInHoverBar;
  final void Function() onTap;
  final void Function(bool)? onOverrideVisibility;

  @override
  State<SaveToPageButton> createState() => _SaveToPageButtonState();
}

class _SaveToPageButtonState extends State<SaveToPageButton> {
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    final userProfile = userWorkspaceBloc.userProfile;
    final workspaceId =
        userWorkspaceBloc.state.currentWorkspace?.workspaceId ?? '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SpaceBloc(
            userProfile: userProfile,
            workspaceId: workspaceId,
          )..add(const SpaceEvent.initial(openFirstPage: false)),
        ),
        BlocProvider(
          create: (context) => ChatSettingsCubit(),
        ),
      ],
      child: BlocSelector<SpaceBloc, SpaceState, ViewPB?>(
        selector: (state) => state.currentSpace,
        builder: (context, spaceView) {
          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            margin: EdgeInsets.zero,
            offset: const Offset(8, 0),
            direction: PopoverDirection.rightWithBottomAligned,
            constraints: const BoxConstraints.tightFor(width: 300, height: 400),
            onClose: () {
              if (spaceView != null) {
                context.read<ChatSettingsCubit>().refreshSources(spaceView);
              }
              widget.onOverrideVisibility?.call(false);
            },
            child: FlowyTooltip(
              message: LocaleKeys.chat_addToPageButton.tr(),
              child: FlowyIconButton(
                width: DesktopAIConvoSizes.actionBarIconSize,
                hoverColor: AFThemeExtension.of(context).lightGreyHover,
                radius: widget.isInHoverBar
                    ? DesktopAIConvoSizes.hoverActionBarIconRadius
                    : DesktopAIConvoSizes.actionBarIconRadius,
                icon: FlowySvg(
                  FlowySvgs.ai_add_to_page_s,
                  color: Theme.of(context).hintColor,
                  size: const Size.square(16),
                ),
                onPressed: () {
                  final documentId = getOpenedDocumentId();
                  if (documentId != null) {
                    onAddToExistingPage(documentId);
                  } else {
                    widget.onOverrideVisibility?.call(true);
                    if (spaceView != null) {
                      context
                          .read<ChatSettingsCubit>()
                          .refreshSources(spaceView);
                    }
                    popoverController.show();
                  }
                },
              ),
            ),
            popupBuilder: (_) => BlocProvider.value(
              value: context.read<ChatSettingsCubit>(),
              child: _PopoverContent(
                onAddToNewPage: () {
                  addMessageToNewPage(context);
                  popoverController.close();
                },
                onAddToExistingPage: (documentId) async {
                  onAddToExistingPage(documentId);
                  final _ =
                      await ViewBackendService.getView(documentId).toNullable();
                  // if (context.mounted) {
                  //   openPageFromMessage(context, view);
                  // }
                  popoverController.close();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void onAddToExistingPage(String documentId) {
    ChatEditDocumentService.addMessageToPage(
      documentId,
      widget.textMessage,
    );
  }

  void addMessageToNewPage(BuildContext context) async {
    final chatView = await ViewBackendService.getView(
      context.read<ChatAIMessageBloc>().chatId,
    ).toNullable();
    if (chatView != null) {
      final _ = await ChatEditDocumentService.saveMessagesToNewPage(
        chatView.parentViewId,
        [widget.textMessage],
      );
      // if (context.mounted) {
      //   openPageFromMessage(context, newView);
      // }
    }
  }

  String? getOpenedDocumentId() {
    final pageManager = getIt<TabsBloc>().state.currentPageManager;
    if (!pageManager.showSecondaryPluginNotifier.value) {
      return null;
    }
    return pageManager.secondaryNotifier.plugin.id;
  }
}

class _PopoverContent extends StatelessWidget {
  const _PopoverContent({
    required this.onAddToNewPage,
    required this.onAddToExistingPage,
  });

  final void Function() onAddToNewPage;
  final void Function(String) onAddToExistingPage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatSettingsCubit, ChatSettingsState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 24,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FlowyText(
                  LocaleKeys.chat_addToPageTitle.tr(),
                  fontSize: 12.0,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: SpaceSearchField(
                width: 600,
                onSearch: (context, value) =>
                    context.read<ChatSettingsCubit>().updateFilter(value),
              ),
            ),
            _buildDivider(),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                children: _buildVisibleSources(context, state).toList(),
              ),
            ),
            _buildDivider(),
            _addToNewPageButton(context),
          ],
        );
      },
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1.0,
      thickness: 1.0,
      indent: 12.0,
      endIndent: 12.0,
    );
  }

  Iterable<Widget> _buildVisibleSources(
    BuildContext context,
    ChatSettingsState state,
  ) {
    return state.visibleSources
        .where((e) => e.ignoreStatus != IgnoreViewType.hide)
        .map(
          (e) => ChatSourceTreeItem(
            key: ValueKey(
              'save_to_page_tree_item_${e.view.id}',
            ),
            chatSource: e,
            level: 0,
            isDescendentOfSpace: e.view.isSpace,
            isSelectedSection: false,
            showCheckbox: false,
            onSelected: (source) {
              if (!source.view.isSpace) {
                onAddToExistingPage(source.view.id);
              }
            },
            height: 30.0,
          ),
        );
  }

  Widget _addToNewPageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 30,
        child: FlowyButton(
          iconPadding: 8,
          onTap: onAddToNewPage,
          text: FlowyText(
            LocaleKeys.chat_addToNewPage.tr(),
            figmaLineHeight: 20,
          ),
          leftIcon: FlowySvg(
            FlowySvgs.add_m,
            size: const Size.square(16),
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class ChatAIMessagePopup extends StatelessWidget {
  const ChatAIMessagePopup({
    super.key,
    required this.child,
    required this.message,
    this.onRegenerate,
  });

  final Widget child;
  final Message message;
  final void Function()? onRegenerate;

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
                const VSpace(16.0),
                _copyButton(context, bottomSheetContext),
                const Divider(height: 8.5, thickness: 0.5),
                _regenerateButton(context),
                const Divider(height: 8.5, thickness: 0.5),
                _saveToPageButton(context),
                const Divider(height: 8.5, thickness: 0.5),
              ],
            );
          },
        );
      },
      child: child,
    );
  }

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
      icon: FlowySvgs.ai_undo_s,
      iconSize: const Size.square(20),
      text: LocaleKeys.chat_regenerate.tr(),
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

        ChatEditDocumentService.addMessageToPage(
          selectedView.id,
          message as TextMessage,
        );

        if (context.mounted) {
          context.pop();
          // unawaited(context.pushView(selectedView));
        }
      },
      icon: FlowySvgs.ai_add_to_page_s,
      iconSize: const Size.square(20),
      text: LocaleKeys.chat_addToPageButton.tr(),
    );
  }
}

import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_edit_document_service.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_sources_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
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

import '../chat_input/select_sources_menu.dart';
import '../layout_define.dart';
import 'message_util.dart';

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
    this.onOverrideVisibility,
  });

  final TextMessage textMessage;
  final bool isInHoverBar;
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
            child: buildButton(context, spaceView),
            popupBuilder: (_) => buildPopover(context),
          );
        },
      ),
    );
  }

  Widget buildButton(BuildContext context, ViewPB? spaceView) {
    return FlowyTooltip(
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
        onPressed: () async {
          final documentId = getOpenedDocumentId();
          if (documentId != null) {
            await onAddToExistingPage(documentId);
          } else {
            widget.onOverrideVisibility?.call(true);
            if (spaceView != null) {
              context.read<ChatSettingsCubit>().refreshSources(spaceView);
            }
            popoverController.show();
          }
        },
      ),
    );
  }

  Widget buildPopover(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ChatSettingsCubit>(),
      child: _SaveToPagePopoverContent(
        onAddToNewPage: () {
          addMessageToNewPage(context);
          popoverController.close();
        },
        onAddToExistingPage: (documentId) async {
          await onAddToExistingPage(documentId);
          final view =
              await ViewBackendService.getView(documentId).toNullable();
          if (context.mounted) {
            openPageFromMessage(context, view);
          }
          popoverController.close();
        },
      ),
    );
  }

  Future<void> onAddToExistingPage(String documentId) {
    return ChatEditDocumentService.addMessageToPage(
      documentId,
      widget.textMessage,
    );
  }

  void addMessageToNewPage(BuildContext context) async {
    final chatView = await ViewBackendService.getView(
      context.read<ChatAIMessageBloc>().chatId,
    ).toNullable();
    if (chatView != null) {
      final newView = await ChatEditDocumentService.saveMessagesToNewPage(
        chatView.nameOrDefault,
        chatView.parentViewId,
        [widget.textMessage],
      );
      if (context.mounted) {
        openPageFromMessage(context, newView);
      }
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

class _SaveToPagePopoverContent extends StatelessWidget {
  const _SaveToPagePopoverContent({
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

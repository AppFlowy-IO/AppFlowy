import 'dart:async';
import 'dart:convert';

import 'package:appflowy/ai/widgets/prompt_input/layout_define.dart';
import 'package:appflowy/ai/widgets/prompt_input/predefined_format_buttons.dart';
import 'package:appflowy/ai/widgets/prompt_input/select_sources_menu.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_edit_document_service.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_sources_cubit.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
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
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import '../layout_define.dart';
import 'message_util.dart';

class AIMessageActionBar extends StatefulWidget {
  const AIMessageActionBar({
    super.key,
    required this.message,
    required this.showDecoration,
    this.onRegenerate,
    this.onChangeFormat,
    this.onOverrideVisibility,
  });

  final Message message;
  final bool showDecoration;
  final void Function()? onRegenerate;
  final void Function(PredefinedFormat)? onChangeFormat;
  final void Function(bool)? onOverrideVisibility;

  @override
  State<AIMessageActionBar> createState() => _AIMessageActionBarState();
}

class _AIMessageActionBarState extends State<AIMessageActionBar> {
  final popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;

    final child = SeparatedRow(
      mainAxisSize: MainAxisSize.min,
      separatorBuilder: () => const HSpace(8.0),
      children: _buildChildren(),
    );

    return widget.showDecoration
        ? Container(
            padding: DesktopAIChatSizes.messageHoverActionBarPadding,
            decoration: BoxDecoration(
              borderRadius: DesktopAIChatSizes.messageHoverActionBarRadius,
              border: Border.all(
                color: isLightMode
                    ? const Color(0x1F1F2329)
                    : Theme.of(context).dividerColor,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  spreadRadius: -2,
                  color: isLightMode
                      ? const Color(0x051F2329)
                      : Theme.of(context).shadowColor.withValues(alpha: 0.02),
                ),
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: isLightMode
                      ? const Color(0x051F2329)
                      : Theme.of(context).shadowColor.withValues(alpha: 0.02),
                ),
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 2,
                  color: isLightMode
                      ? const Color(0x051F2329)
                      : Theme.of(context).shadowColor.withValues(alpha: 0.02),
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
        isInHoverBar: widget.showDecoration,
        textMessage: widget.message as TextMessage,
      ),
      RegenerateButton(
        isInHoverBar: widget.showDecoration,
        onTap: () => widget.onRegenerate?.call(),
      ),
      ChangeFormatButton(
        isInHoverBar: widget.showDecoration,
        onRegenerate: widget.onChangeFormat,
        popoverMutex: popoverMutex,
        onOverrideVisibility: widget.onOverrideVisibility,
      ),
      SaveToPageButton(
        textMessage: widget.message as TextMessage,
        isInHoverBar: widget.showDecoration,
        popoverMutex: popoverMutex,
        onOverrideVisibility: widget.onOverrideVisibility,
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
        width: DesktopAIChatSizes.messageActionBarIconSize,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: isInHoverBar
            ? DesktopAIChatSizes.messageHoverActionBarIconRadius
            : DesktopAIChatSizes.messageActionBarIconRadius,
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
        width: DesktopAIChatSizes.messageActionBarIconSize,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: isInHoverBar
            ? DesktopAIChatSizes.messageHoverActionBarIconRadius
            : DesktopAIChatSizes.messageActionBarIconRadius,
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

class ChangeFormatButton extends StatefulWidget {
  const ChangeFormatButton({
    super.key,
    required this.isInHoverBar,
    this.popoverMutex,
    this.onRegenerate,
    this.onOverrideVisibility,
  });

  final bool isInHoverBar;
  final PopoverMutex? popoverMutex;
  final void Function(PredefinedFormat)? onRegenerate;
  final void Function(bool)? onOverrideVisibility;

  @override
  State<ChangeFormatButton> createState() => _ChangeFormatButtonState();
}

class _ChangeFormatButtonState extends State<ChangeFormatButton> {
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      mutex: widget.popoverMutex,
      triggerActions: PopoverTriggerFlags.none,
      margin: EdgeInsets.zero,
      offset: Offset(0, widget.isInHoverBar ? 8 : 4),
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: const BoxConstraints(),
      onClose: () => widget.onOverrideVisibility?.call(false),
      child: buildButton(context),
      popupBuilder: (_) => _ChangeFormatPopoverContent(
        onRegenerate: widget.onRegenerate,
      ),
    );
  }

  Widget buildButton(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.chat_changeFormat_actionButton.tr(),
      child: FlowyIconButton(
        width: 32.0,
        height: DesktopAIChatSizes.messageActionBarIconSize,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: widget.isInHoverBar
            ? DesktopAIChatSizes.messageHoverActionBarIconRadius
            : DesktopAIChatSizes.messageActionBarIconRadius,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowySvg(
              FlowySvgs.ai_retry_font_s,
              color: Theme.of(context).hintColor,
              size: const Size.square(16),
            ),
            FlowySvg(
              FlowySvgs.ai_source_drop_down_s,
              color: Theme.of(context).hintColor,
              size: const Size.square(8),
            ),
          ],
        ),
        onPressed: () {
          widget.onOverrideVisibility?.call(true);
          popoverController.show();
        },
      ),
    );
  }
}

class _ChangeFormatPopoverContent extends StatefulWidget {
  const _ChangeFormatPopoverContent({
    this.onRegenerate,
  });

  final void Function(PredefinedFormat)? onRegenerate;

  @override
  State<_ChangeFormatPopoverContent> createState() =>
      _ChangeFormatPopoverContentState();
}

class _ChangeFormatPopoverContentState
    extends State<_ChangeFormatPopoverContent> {
  PredefinedFormat? predefinedFormat;

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;
    return Container(
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        borderRadius: DesktopAIChatSizes.messageHoverActionBarRadius,
        border: Border.all(
          color: isLightMode
              ? const Color(0x1F1F2329)
              : Theme.of(context).dividerColor,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -2,
            color: isLightMode
                ? const Color(0x051F2329)
                : Theme.of(context).shadowColor.withValues(alpha: 0.02),
          ),
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: isLightMode
                ? const Color(0x051F2329)
                : Theme.of(context).shadowColor.withValues(alpha: 0.02),
          ),
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 2,
            color: isLightMode
                ? const Color(0x051F2329)
                : Theme.of(context).shadowColor.withValues(alpha: 0.02),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChangeFormatBar(
            spacing: 2.0,
            predefinedFormat: predefinedFormat,
            onSelectPredefinedFormat: (format) {
              setState(() => predefinedFormat = format);
            },
          ),
          const HSpace(4.0),
          FlowyTooltip(
            message: LocaleKeys.chat_changeFormat_confirmButton.tr(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.onRegenerate
                      ?.call(predefinedFormat ?? const PredefinedFormat.auto());
                },
                child: SizedBox.square(
                  dimension: DesktopAIPromptSizes.predefinedFormatButtonHeight,
                  child: Center(
                    child: FlowySvg(
                      FlowySvgs.ai_retry_filled_s,
                      color: Theme.of(context).colorScheme.primary,
                      size: const Size.square(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SaveToPageButton extends StatefulWidget {
  const SaveToPageButton({
    super.key,
    required this.textMessage,
    required this.isInHoverBar,
    this.popoverMutex,
    this.onOverrideVisibility,
  });

  final TextMessage textMessage;
  final bool isInHoverBar;
  final PopoverMutex? popoverMutex;
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
          create: (context) => ChatSettingsCubit(hideDisabled: true),
        ),
      ],
      child: BlocSelector<SpaceBloc, SpaceState, ViewPB?>(
        selector: (state) => state.currentSpace,
        builder: (context, spaceView) {
          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            margin: EdgeInsets.zero,
            mutex: widget.popoverMutex,
            offset: const Offset(8, 0),
            direction: PopoverDirection.rightWithBottomAligned,
            constraints: const BoxConstraints.tightFor(width: 300, height: 400),
            onClose: () {
              if (spaceView != null) {
                context
                    .read<ChatSettingsCubit>()
                    .refreshSources([spaceView], spaceView);
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
        width: DesktopAIChatSizes.messageActionBarIconSize,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: widget.isInHoverBar
            ? DesktopAIChatSizes.messageHoverActionBarIconRadius
            : DesktopAIChatSizes.messageActionBarIconRadius,
        icon: FlowySvg(
          FlowySvgs.ai_add_to_page_s,
          color: Theme.of(context).hintColor,
          size: const Size.square(16),
        ),
        onPressed: () async {
          final documentId = getOpenedDocumentId();
          if (documentId != null) {
            await onAddToExistingPage(context, documentId);
            await forceReload(documentId);
            await Future.delayed(const Duration(milliseconds: 500));
            await updateSelection(documentId);
          } else {
            widget.onOverrideVisibility?.call(true);
            if (spaceView != null) {
              context
                  .read<ChatSettingsCubit>()
                  .refreshSources([spaceView], spaceView);
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
        onAddToNewPage: (parentViewId) {
          addMessageToNewPage(context, parentViewId);
          popoverController.close();
        },
        onAddToExistingPage: (documentId) async {
          popoverController.close();
          final view = await onAddToExistingPage(context, documentId);

          if (context.mounted) {
            openPageFromMessage(context, view);
          }
          await Future.delayed(const Duration(milliseconds: 500));
          await updateSelection(documentId);
        },
      ),
    );
  }

  Future<ViewPB?> onAddToExistingPage(
    BuildContext context,
    String documentId,
  ) async {
    await ChatEditDocumentService.addMessageToPage(
      documentId,
      widget.textMessage,
    );
    await Future.delayed(const Duration(milliseconds: 500));
    final view = await ViewBackendService.getView(documentId).toNullable();
    if (context.mounted) {
      showSaveMessageSuccessToast(context, view);
    }
    return view;
  }

  void addMessageToNewPage(BuildContext context, String parentViewId) async {
    final chatView = await ViewBackendService.getView(
      context.read<ChatAIMessageBloc>().chatId,
    ).toNullable();
    if (chatView != null) {
      final newView = await ChatEditDocumentService.saveMessagesToNewPage(
        chatView.nameOrDefault,
        parentViewId,
        [widget.textMessage],
      );

      if (context.mounted) {
        showSaveMessageSuccessToast(context, newView);
        openPageFromMessage(context, newView);
      }
    }
  }

  void showSaveMessageSuccessToast(BuildContext context, ViewPB? view) {
    if (view == null) {
      return;
    }
    showToastNotification(
      context,
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: LocaleKeys.chat_addToNewPageSuccessToast.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFFFFFFF),
                ),
          ),
          const TextSpan(
            text: ' ',
          ),
          TextSpan(
            text: view.nameOrDefault,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> forceReload(String documentId) async {
    final bloc = DocumentBloc.findOpen(documentId);
    if (bloc == null) {
      return;
    }
    await bloc.forceReloadDocumentState();
  }

  Future<void> updateSelection(String documentId) async {
    final bloc = DocumentBloc.findOpen(documentId);
    if (bloc == null) {
      return;
    }
    await bloc.forceReloadDocumentState();
    final editorState = bloc.state.editorState;
    final lastNodePath = editorState?.getLastSelectable()?.$1.path;
    if (editorState == null || lastNodePath == null) {
      return;
    }
    unawaited(
      editorState.updateSelectionWithReason(
        Selection.collapsed(Position(path: lastNodePath)),
      ),
    );
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

  final void Function(String) onAddToNewPage;
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
            showSaveButton: true,
            onSelected: (source) {
              if (source.view.isSpace) {
                onAddToNewPage(source.view.id);
              } else {
                onAddToExistingPage(source.view.id);
              }
            },
            onAdd: (source) {
              onAddToNewPage(source.view.id);
            },
            height: 30.0,
          ),
        );
  }
}

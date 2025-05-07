import 'dart:async';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_edit_document_service.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_message_bloc.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import 'message/ai_message_action_bar.dart';
import 'message/message_util.dart';

class ChatMessageSelectorBanner extends StatelessWidget {
  const ChatMessageSelectorBanner({
    super.key,
    required this.view,
    this.allMessages = const [],
  });

  final ViewPB view;
  final List<Message> allMessages;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatSelectMessageBloc, ChatSelectMessageState>(
      builder: (context, state) {
        if (!state.isSelectingMessages) {
          return const SizedBox.shrink();
        }

        final selectedAmount = state.selectedMessages.length;
        final totalAmount = allMessages.length;
        final allSelected = selectedAmount == totalAmount;

        return Container(
          height: 48,
          color: const Color(0xFF00BCF0),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (selectedAmount > 0) {
                    _unselectAllMessages(context);
                  } else {
                    _selectAllMessages(context);
                  }
                },
                child: FlowySvg(
                  allSelected
                      ? FlowySvgs.checkbox_ai_selected_s
                      : selectedAmount > 0
                          ? FlowySvgs.checkbox_ai_minus_s
                          : FlowySvgs.checkbox_ai_empty_s,
                  blendMode: BlendMode.dstIn,
                  size: const Size.square(18),
                ),
              ),
              const HSpace(8),
              Expanded(
                child: FlowyText.semibold(
                  allSelected
                      ? LocaleKeys.chat_selectBanner_allSelected.tr()
                      : selectedAmount > 0
                          ? LocaleKeys.chat_selectBanner_nSelected
                              .tr(args: [selectedAmount.toString()])
                          : LocaleKeys.chat_selectBanner_selectMessages.tr(),
                  figmaLineHeight: 16,
                  color: Colors.white,
                ),
              ),
              SaveToPageButton(
                view: view,
              ),
              const HSpace(8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.read<ChatSelectMessageBloc>().add(
                        const ChatSelectMessageEvent.toggleSelectingMessages(),
                      ),
                  child: const FlowySvg(
                    FlowySvgs.close_m,
                    color: Colors.white,
                    size: Size.square(24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectAllMessages(BuildContext context) => context
      .read<ChatSelectMessageBloc>()
      .add(ChatSelectMessageEvent.selectAllMessages(allMessages));

  void _unselectAllMessages(BuildContext context) => context
      .read<ChatSelectMessageBloc>()
      .add(const ChatSelectMessageEvent.unselectAllMessages());
}

class SaveToPageButton extends StatefulWidget {
  const SaveToPageButton({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  State<SaveToPageButton> createState() => _SaveToPageButtonState();
}

class _SaveToPageButtonState extends State<SaveToPageButton> {
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return ViewSelector(
      viewSelectorCubit: BlocProvider(
        create: (context) => ViewSelectorCubit(
          getIgnoreViewType: (view) {
            if (view.isSpace) {
              return IgnoreViewType.none;
            }
            if (view.layout != ViewLayoutPB.Document) {
              return IgnoreViewType.hide;
            }
            return IgnoreViewType.none;
          },
        ),
      ),
      child: BlocSelector<SpaceBloc, SpaceState, ViewPB?>(
        selector: (state) => state.currentSpace,
        builder: (context, spaceView) {
          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            margin: EdgeInsets.zero,
            offset: const Offset(0, 18),
            direction: PopoverDirection.bottomWithRightAligned,
            constraints: const BoxConstraints.tightFor(width: 300, height: 400),
            child: buildButton(context, spaceView),
            popupBuilder: (_) => buildPopover(context),
          );
        },
      ),
    );
  }

  Widget buildButton(BuildContext context, ViewPB? spaceView) {
    return BlocBuilder<ChatSelectMessageBloc, ChatSelectMessageState>(
      builder: (context, state) {
        final selectedAmount = state.selectedMessages.length;

        return Opacity(
          opacity: selectedAmount == 0 ? 0.5 : 1,
          child: FlowyTextButton(
            LocaleKeys.chat_selectBanner_saveButton.tr(),
            onPressed: selectedAmount == 0
                ? null
                : () async {
                    final documentId = getOpenedDocumentId();
                    if (documentId != null) {
                      await onAddToExistingPage(context, documentId);
                      await forceReload(documentId);
                      await Future.delayed(const Duration(milliseconds: 500));
                      await updateSelection(documentId);
                    } else {
                      if (spaceView != null) {
                        context
                            .read<ViewSelectorCubit>()
                            .refreshSources([spaceView], spaceView);
                      }
                      popoverController.show();
                    }
                  },
            fontColor: Colors.white,
            borderColor: Colors.white,
            fillColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
          ),
        );
      },
    );
  }

  Widget buildPopover(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ViewSelectorCubit>(),
      child: SaveToPagePopoverContent(
        onAddToNewPage: (parentViewId) async {
          await addMessageToNewPage(context, parentViewId);
          popoverController.close();
        },
        onAddToExistingPage: (documentId) async {
          final view = await onAddToExistingPage(context, documentId);

          if (context.mounted) {
            openPageFromMessage(context, view);
          }
          await Future.delayed(const Duration(milliseconds: 500));
          await updateSelection(documentId);
          popoverController.close();
        },
      ),
    );
  }

  Future<ViewPB?> onAddToExistingPage(
    BuildContext context,
    String documentId,
  ) async {
    final bloc = context.read<ChatSelectMessageBloc>();

    final selectedMessages = [
      ...bloc.state.selectedMessages.whereType<TextMessage>(),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    await ChatEditDocumentService.addMessagesToPage(
      documentId,
      selectedMessages,
    );
    await Future.delayed(const Duration(milliseconds: 500));
    final view = await ViewBackendService.getView(documentId).toNullable();
    if (context.mounted) {
      showSaveMessageSuccessToast(context, view);
    }

    bloc.add(const ChatSelectMessageEvent.reset());

    return view;
  }

  Future<void> addMessageToNewPage(
    BuildContext context,
    String parentViewId,
  ) async {
    final bloc = context.read<ChatSelectMessageBloc>();

    final selectedMessages = [
      ...bloc.state.selectedMessages.whereType<TextMessage>(),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final newView = await ChatEditDocumentService.saveMessagesToNewPage(
      widget.view.nameOrDefault,
      parentViewId,
      selectedMessages,
    );

    if (context.mounted) {
      showSaveMessageSuccessToast(context, newView);
      openPageFromMessage(context, newView);
    }
    bloc.add(const ChatSelectMessageEvent.reset());
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

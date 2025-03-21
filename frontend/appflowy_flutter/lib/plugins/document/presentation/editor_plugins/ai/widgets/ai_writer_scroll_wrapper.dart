import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/throttle.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../operations/ai_writer_cubit.dart';
import 'ai_writer_gesture_detector.dart';

class AiWriterScrollWrapper extends StatefulWidget {
  const AiWriterScrollWrapper({
    super.key,
    required this.viewId,
    required this.editorState,
    required this.child,
  });

  final String viewId;
  final EditorState editorState;
  final Widget child;

  @override
  State<AiWriterScrollWrapper> createState() => _AiWriterScrollWrapperState();
}

class _AiWriterScrollWrapperState extends State<AiWriterScrollWrapper> {
  final overlayController = OverlayPortalController();
  late final throttler = Throttler();
  late final aiWriterCubit = AiWriterCubit(
    documentId: widget.viewId,
    editorState: widget.editorState,
    onCreateNode: () {
      aiWriterRegistered = true;
      widget.editorState.service.keyboardService?.disableShortcuts();
      HardwareKeyboard.instance.addHandler(cancelShortcutHandler);
    },
    onRemoveNode: () {
      aiWriterRegistered = false;
      HardwareKeyboard.instance.removeHandler(cancelShortcutHandler);
      widget.editorState.service.keyboardService?.enableShortcuts();
    },
    onAppendToDocument: onAppendToDocument,
  );

  bool userHasScrolled = false;
  bool aiWriterRegistered = false;

  @override
  void initState() {
    super.initState();
    overlayController.show();
  }

  @override
  void dispose() {
    aiWriterCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: aiWriterCubit,
      child: NotificationListener<ScrollNotification>(
        onNotification: handleScrollNotification,
        child: MultiBlocListener(
          listeners: [
            BlocListener<AiWriterCubit, AiWriterState>(
              listener: (context, state) {
                if (state is DocumentContentEmptyAiWriterState) {
                  showConfirmDialog(
                    context: context,
                    title: LocaleKeys.ai_continueWritingEmptyDocumentTitle.tr(),
                    description: LocaleKeys
                        .ai_continueWritingEmptyDocumentDescription
                        .tr(),
                    onConfirm: state.onConfirm,
                  );
                }
              },
            ),
            BlocListener<AiWriterCubit, AiWriterState>(
              listenWhen: (previous, current) =>
                  previous is GeneratingAiWriterState &&
                  current is ReadyAiWriterState,
              listener: (context, state) {
                widget.editorState.updateSelectionWithReason(null);
              },
            ),
          ],
          child: OverlayPortal(
            controller: overlayController,
            overlayChildBuilder: (context) {
              return BlocBuilder<AiWriterCubit, AiWriterState>(
                builder: (context, state) {
                  return AiWriterGestureDetector(
                    behavior: state is RegisteredAiWriter
                        ? HitTestBehavior.translucent
                        : HitTestBehavior.deferToChild,
                    onPointerEvent: () => onTapOutside(context),
                  );
                },
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }

  bool handleScrollNotification(ScrollNotification notification) {
    if (!aiWriterRegistered) {
      return false;
    }

    if (notification is UserScrollNotification) {
      debounceResetUserHasScrolled();
      userHasScrolled = true;
      throttler.cancel();
    }

    return false;
  }

  void debounceResetUserHasScrolled() {
    Debounce.debounce(
      'user_has_scrolled',
      const Duration(seconds: 3),
      () => userHasScrolled = false,
    );
  }

  void onTapOutside(BuildContext context) {
    final aiWriterCubit = context.read<AiWriterCubit>();

    if (aiWriterCubit.hasUnusedResponse()) {
      showConfirmDialog(
        context: context,
        title: LocaleKeys.button_discard.tr(),
        description: LocaleKeys.document_plugins_discardResponse.tr(),
        confirmLabel: LocaleKeys.button_discard.tr(),
        style: ConfirmPopupStyle.cancelAndOk,
        onConfirm: stopAndExit,
        onCancel: () {},
      );
    } else {
      stopAndExit();
    }
  }

  bool cancelShortcutHandler(KeyEvent event) {
    if (event is! KeyUpEvent) {
      return false;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        if (aiWriterCubit.state case GeneratingAiWriterState _) {
          aiWriterCubit.stopStream();
        } else if (aiWriterCubit.hasUnusedResponse()) {
          showConfirmDialog(
            context: context,
            title: LocaleKeys.button_discard.tr(),
            description: LocaleKeys.document_plugins_discardResponse.tr(),
            confirmLabel: LocaleKeys.button_discard.tr(),
            style: ConfirmPopupStyle.cancelAndOk,
            onConfirm: stopAndExit,
            onCancel: () {},
          );
        } else {
          stopAndExit();
        }
        return true;
      case LogicalKeyboardKey.keyC
          when HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.controlLeft):
        if (aiWriterCubit.state case GeneratingAiWriterState _) {
          aiWriterCubit.stopStream();
        }
        return true;
      default:
        break;
    }

    return false;
  }

  void onAppendToDocument() {
    if (!aiWriterRegistered || userHasScrolled) {
      return;
    }

    throttler.call(() {
      if (aiWriterCubit.aiWriterNode != null) {
        final path = aiWriterCubit.aiWriterNode!.path;
        widget.editorState.updateSelectionWithReason(
          Selection.collapsed(Position(path: path)),
        );
      }
    });
  }

  void stopAndExit() {
    Future(() async {
      await aiWriterCubit.stopStream();
      await aiWriterCubit.exit();
    });
  }
}

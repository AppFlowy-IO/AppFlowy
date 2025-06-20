import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/features/mension_person/presentation/mobile_mention_menu_service.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

const inlineActionCharacter = '@';

CharacterShortcutEvent inlineActionsCommand(
  InlineActionsService inlineActionsService, {
  InlineActionsMenuStyle style = const InlineActionsMenuStyle.light(),
}) =>
    CharacterShortcutEvent(
      key: 'Opens Inline Actions Menu',
      character: inlineActionCharacter,
      handler: (editorState) => inlineActionsCommandHandler(
        editorState,
        inlineActionsService.context,
      ),
    );

InlineActionsMenuService? selectionMenuService;

Future<bool> inlineActionsCommandHandler(
  EditorState editorState,
  BuildContext? context,
) async {
  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  await editorState.insertTextAtPosition(
    inlineActionCharacter,
    position: selection.start,
  );

  final workspaceBloc = context?.read<UserWorkspaceBloc?>();
  final documentBloc = context?.read<DocumentBloc?>();
  final reminderBloc = context?.read<ReminderBloc?>();

  if (context != null &&
      context.mounted &&
      workspaceBloc != null &&
      documentBloc != null &&
      reminderBloc != null) {
    keepEditorFocusNotifier.increase();
    selectionMenuService?.dismiss();
    selectionMenuService = UniversalPlatform.isMobile
        ? MobileMentionMenuService(
            context: context,
            editorState: editorState,
            workspaceBloc: workspaceBloc,
            documentBloc: documentBloc,
            reminderBloc: reminderBloc,
          )
        : DesktopMentionMenuService(
            context: context,
            editorState: editorState,
            workspaceBloc: workspaceBloc,
            documentBloc: documentBloc,
            reminderBloc: reminderBloc,
          );

    // disable the keyboard service
    editorState.service.keyboardService?.disable();

    await selectionMenuService?.show();

    // enable the keyboard service
    editorState.service.keyboardService?.enable();
  }

  return true;
}

import 'package:appflowy/mobile/presentation/inline_actions/mobile_inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:universal_platform/universal_platform.dart';

const hashtagActionCharacter = '#';

InlineActionsMenuService? selectionMenuService;

CharacterShortcutEvent hashtagActionsCommand(
  InlineActionsService inlineActionsService, {
  InlineActionsMenuStyle style = const InlineActionsMenuStyle.light(),
}) =>
    CharacterShortcutEvent(
      key: 'Opens Hashtag Menu',
      character: hashtagActionCharacter,
      handler: (editorState) => hashtagActionsCommandHandler(
        editorState,
        inlineActionsService,
        style,
      ),
    );

Future<bool> hashtagActionsCommandHandler(
  EditorState editorState,
  InlineActionsService service,
  InlineActionsMenuStyle style,
) async {
  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  await editorState.insertTextAtPosition(
    hashtagActionCharacter,
    position: selection.start,
  );

  final List<InlineActionsResult> initialResults = [];
  for (final handler in service.handlers) {
    final group = await handler.search(null);

    if (group.results.isNotEmpty) {
      initialResults.add(group);
    }
  }

  if (service.context != null) {
    keepEditorFocusNotifier.increase();
    selectionMenuService?.dismiss();
    selectionMenuService = UniversalPlatform.isMobile
        ? MobileInlineActionsMenu(
            context: service.context!,
            editorState: editorState,
            service: service,
            initialResults: initialResults,
            style: style,
          )
        : InlineActionsMenu(
            context: service.context!,
            editorState: editorState,
            service: service,
            initialResults: initialResults,
            style: style,
          );

    editorState.service.keyboardService?.disable();
    await selectionMenuService?.show();
    editorState.service.keyboardService?.enable();
  }

  return true;
}
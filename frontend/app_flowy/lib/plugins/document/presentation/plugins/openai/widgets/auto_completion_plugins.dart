import 'package:app_flowy/plugins/document/presentation/plugins/openai/service/openai_client.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import '../util/editor_extension.dart';

SelectionMenuItem autoCompletionMenuItem = SelectionMenuItem(
  name: () => LocaleKeys.document_plugins_autoCompletionMenuItemName.tr(),
  icon: (editorState, onSelected) => Icon(
    Icons.rocket,
    size: 18.0,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
  ),
  keywords: ['auto completion', 'ai'],
  handler: ((editorState, menuService, context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: _AutoCompletionInput(
            editorState: editorState,
          ),
        );
      },
    );
  }),
);

class _AutoCompletionInput extends StatelessWidget {
  _AutoCompletionInput({
    required this.editorState,
  });

  final EditorState editorState;
  final controller = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      child: TextField(
        autofocus: true,
        controller: controller,
        maxLines: null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Please input something...',
        ),
      ),
      onKey: (key) async {
        if (key is! RawKeyDownEvent) return;
        if (key.logicalKey == LogicalKeyboardKey.enter) {
          Navigator.of(context).pop();
          // fetch the result and insert it
          final result = await UserService.getCurrentUserProfile();
          result.fold((userProfile) {
            HttpOpenAIRepository(
              client: http.Client(),
              apiKey: userProfile.openaiKey,
            ).getCompletions(prompt: controller.text).then((result) {
              result.fold((error) {
                // Error.
              }, (textCompletion) async {
                await editorState.autoInsertText(
                  textCompletion.choices.first.text,
                );
              });
            });
          }, (error) {
            // TODO: show a toast.
          });
        } else if (key.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

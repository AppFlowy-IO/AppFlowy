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

class _AutoCompletionInput extends StatefulWidget {
  const _AutoCompletionInput({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  State<_AutoCompletionInput> createState() => _AutoCompletionInputState();
}

class _AutoCompletionInputState extends State<_AutoCompletionInput> {
  final controller = TextEditingController(text: '');

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
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
          // fetch the result and insert it
          final result = await UserService.getCurrentUserProfile();
          result.fold((userProfile) {
            setState(() {
              loading = true;
            });
            HttpOpenAIRepository(
              client: http.Client(),
              apiKey: userProfile.openaiKey,
            ).getCompletions(prompt: controller.text).then((result) {
              result.fold((error) {
                // Error.
                assert(false, 'Error: $error');
              }, (textCompletion) async {
                await widget.editorState.autoInsertText(
                  textCompletion.choices.first.text,
                );
                Navigator.of(context).pop();
              });
            });
          }, (error) {
            // TODO: show a toast.
            assert(false, 'User profile not found.');
          });
        } else if (key.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditUsernameBottomSheet extends StatefulWidget {
  const EditUsernameBottomSheet(
    this.context, {
    this.userName,
    required this.onSubmitted,
    super.key,
  });
  final BuildContext context;
  final String? userName;
  final void Function(String) onSubmitted;
  @override
  State<EditUsernameBottomSheet> createState() =>
      _EditUsernameBottomSheetState();
}

class _EditUsernameBottomSheetState extends State<EditUsernameBottomSheet> {
  late TextEditingController _textFieldController;

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _textFieldController = TextEditingController(text: widget.userName);
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void submitUserName() {
      if (_formKey.currentState!.validate()) {
        final value = _textFieldController.text;
        widget.onSubmitted.call(value);
        widget.context.pop();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleKeys.settings_mobile_username.tr(),
              style: theme.textTheme.labelSmall,
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: theme.hintColor,
              ),
              onPressed: () {
                widget.context.pop();
              },
            ),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _textFieldController,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return LocaleKeys.settings_mobile_usernameEmptyError.tr();
              }
              return null;
            },
            onEditingComplete: submitUserName,
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: submitUserName,
            child: Text(LocaleKeys.button_update.tr()),
          ),
        ),
      ],
    );
  }
}

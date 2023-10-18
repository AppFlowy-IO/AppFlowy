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

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        right: 16,
        left: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Username',
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
              )
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
                  return 'Username cannot be empty';
                }
                return null;
              },
              onEditingComplete: () {
                // show error promts if enter text is empty
                _formKey.currentState!.validate();
              },
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              child: const Text('Update'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final value = _textFieldController.text;
                  widget.onSubmitted.call(value);
                  widget.context.pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

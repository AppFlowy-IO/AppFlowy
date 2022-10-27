import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class InputTextField extends StatefulWidget {
  final void Function(String)? onDone;
  final void Function(String)? onChanged;
  final void Function() onCanceled;
  final bool autoClearWhenDone;
  final String text;
  final int? maxLength;

  const InputTextField({
    required this.text,
    this.onDone,
    required this.onCanceled,
    this.onChanged,
    this.autoClearWhenDone = false,
    this.maxLength,
    Key? key,
  }) : super(key: key);

  @override
  State<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends State<InputTextField> {
  late FocusNode _focusNode;
  var isEdited = false;
  late TextEditingController _controller;

  @override
  void initState() {
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.text);

    _focusNode.addListener(notifyDidEndEditing);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;

    final height = widget.maxLength == null ? 36.0 : 56.0;

    return RoundedInputField(
      controller: _controller,
      focusNode: _focusNode,
      autoFocus: true,
      height: height,
      maxLength: widget.maxLength,
      style: TextStyles.body1.size(13),
      normalBorderColor: theme.shader4,
      focusBorderColor: theme.main1,
      cursorColor: theme.main1,
      onChanged: (text) {
        if (widget.onChanged != null) {
          widget.onChanged!(text);
        }
      },
      onEditingComplete: (_) {
        if (widget.onDone != null) {
          widget.onDone!(_controller.text);
        }

        if (widget.autoClearWhenDone) {
          _controller.text = "";
        }
      },
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(notifyDidEndEditing);
    _focusNode.dispose();
    super.dispose();
  }

  void notifyDidEndEditing() {
    if (!_focusNode.hasFocus) {
      if (_controller.text.isEmpty) {
        widget.onCanceled();
      } else {
        if (widget.onDone != null) {
          widget.onDone!(_controller.text);
        }
      }
    }
  }
}

class TypeOptionSeparator extends StatelessWidget {
  const TypeOptionSeparator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        color: theme.shader4,
        height: 0.25,
      ),
    );
  }
}

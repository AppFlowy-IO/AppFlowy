import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class StyleWidgetBuilder {
  static QuillCheckboxBuilder checkbox() {
    return EditorCheckboxBuilder();
  }
}

class EditorCheckboxBuilder extends QuillCheckboxBuilder {
  EditorCheckboxBuilder();

  @override
  Widget build({required BuildContext context, required bool isChecked, required ValueChanged<bool> onChanged}) {
    return FlowyEditorCheckbox(
      isChecked: isChecked,
      onChanged: onChanged,
    );
  }
}

class FlowyEditorCheckbox extends StatefulWidget {
  const FlowyEditorCheckbox({
    required this.isChecked,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  _FlowyEditorCheckboxState createState() => _FlowyEditorCheckboxState();
}

class _FlowyEditorCheckboxState extends State<FlowyEditorCheckbox> {
  late bool isChecked;

  @override
  void initState() {
    isChecked = widget.isChecked;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final icon = isChecked ? svg('editor/editor_check') : svg('editor/editor_uncheck');
    return Align(
      alignment: Alignment.centerLeft,
      child: FlowyIconButton(
        onPressed: () {
          isChecked = !isChecked;
          widget.onChanged(isChecked);
          setState(() {});
        },
        iconPadding: EdgeInsets.zero,
        icon: icon,
        width: 23,
      ),
    );
  }
}

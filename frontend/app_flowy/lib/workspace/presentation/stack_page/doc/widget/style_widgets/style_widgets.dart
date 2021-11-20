import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class StyleWidgetBuilder {
  static QuillCheckboxBuilder checkbox(AppTheme theme) {
    return EditorCheckboxBuilder(theme);
  }
}

class EditorCheckboxBuilder extends QuillCheckboxBuilder {
  final AppTheme theme;

  EditorCheckboxBuilder(this.theme);

  @override
  Widget build({required BuildContext context, required bool isChecked, required void Function(bool? p1) onChanged}) {
    return FlowyEditorCheckbox(
      theme: theme,
      isChecked: isChecked,
      onChanged: onChanged,
    );
  }
}

class FlowyEditorCheckbox extends StatefulWidget {
  final bool isChecked;
  final void Function(bool? value) onChanged;
  final AppTheme theme;
  const FlowyEditorCheckbox({
    required this.theme,
    required this.isChecked,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

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

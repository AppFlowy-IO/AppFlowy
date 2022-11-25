import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flutter/material.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class FilterTextField extends StatefulWidget {
  final String hintText;
  final String text;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool autoFucous;
  const FilterTextField({
    this.hintText = "",
    this.text = "",
    this.onChanged,
    this.onSubmitted,
    this.autoFucous = true,
    Key? key,
  }) : super(key: key);

  @override
  State<FilterTextField> createState() => FilterTextFieldState();
}

class FilterTextFieldState extends State<FilterTextField> {
  late FocusNode focusNode;
  late TextEditingController controller;

  @override
  void initState() {
    focusNode = FocusNode();
    controller = TextEditingController();
    controller.text = widget.text;
    if (widget.autoFucous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (text) {
        widget.onChanged?.call(text);
      },
      onSubmitted: (text) {
        widget.onSubmitted?.call(text);
      },
      maxLines: 1,
      style: TextStyles.body1.size(FontSizes.s12),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(10),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: Corners.s10Border,
        ),
        isDense: true,
        hintText: widget.hintText,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: Corners.s8Border,
        ),
      ),
    );
  }
}

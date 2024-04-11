import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FlowyMobileSearchTextField extends StatelessWidget {
  const FlowyMobileSearchTextField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.0,
      child: CupertinoSearchTextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        placeholder: hintText,
        prefixIcon: const FlowySvg(FlowySvgs.m_search_m),
        prefixInsets: const EdgeInsets.only(left: 16.0),
        suffixIcon: const Icon(Icons.close),
        suffixInsets: const EdgeInsets.only(right: 16.0),
        placeholderStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w400,
              fontSize: 14.0,
            ),
      ),
    );
  }
}

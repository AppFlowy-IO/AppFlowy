import 'dart:collection';

import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textfield_tags/textfield_tags.dart';

import 'extension.dart';

class SelectOptionTextField extends StatefulWidget {
  final TextfieldTagsController tagController;
  final List<SelectOptionPB> options;
  final LinkedHashMap<String, SelectOptionPB> selectedOptionMap;
  final double distanceToText;

  final Function(String) onNewTag;
  final Function(String) newText;
  final VoidCallback? onClick;

  const SelectOptionTextField({
    required this.options,
    required this.selectedOptionMap,
    required this.distanceToText,
    required this.tagController,
    required this.onNewTag,
    required this.newText,
    this.onClick,
    TextEditingController? textController,
    FocusNode? focusNode,
    Key? key,
  }) : super(key: key);

  @override
  State<SelectOptionTextField> createState() => _SelectOptionTextFieldState();
}

class _SelectOptionTextFieldState extends State<SelectOptionTextField> {
  late FocusNode focusNode;
  late TextEditingController controller;

  @override
  void initState() {
    focusNode = FocusNode();
    controller = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return TextFieldTags(
      textEditingController: controller,
      textfieldTagsController: widget.tagController,
      initialTags: widget.selectedOptionMap.keys.toList(),
      focusNode: focusNode,
      textSeparators: const [','],
      inputfieldBuilder: (
        BuildContext context,
        editController,
        focusNode,
        error,
        onChanged,
        onSubmitted,
      ) {
        return ((context, sc, tags, onTagDelegate) {
          return TextField(
            controller: editController,
            focusNode: focusNode,
            onTap: widget.onClick,
            onChanged: (text) {
              if (onChanged != null) {
                onChanged(text);
              }
              widget.newText(text);
            },
            onSubmitted: (text) {
              if (onSubmitted != null) {
                onSubmitted(text);
              }

              if (text.isNotEmpty) {
                widget.onNewTag(text);
                focusNode.requestFocus();
              }
            },
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.main1, width: 1.0),
                borderRadius: Corners.s10Border,
              ),
              isDense: true,
              prefixIcon: _renderTags(context, sc),
              hintText: LocaleKeys.grid_selectOption_searchOption.tr(),
              prefixIconConstraints:
                  BoxConstraints(maxWidth: widget.distanceToText),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.main1, width: 1.0),
                borderRadius: Corners.s10Border,
              ),
            ),
          );
        });
      },
    );
  }

  Widget? _renderTags(BuildContext context, ScrollController sc) {
    if (widget.selectedOptionMap.isEmpty) {
      return null;
    }

    final children = widget.selectedOptionMap.values
        .map((option) =>
            SelectOptionTag.fromOption(context: context, option: option))
        .toList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        controller: sc,
        scrollDirection: Axis.horizontal,
        child: Wrap(spacing: 4, children: children),
      ),
    );
  }
}

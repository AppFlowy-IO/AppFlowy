import 'dart:collection';

import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flutter/services.dart';
import 'package:textfield_tags/textfield_tags.dart';

import 'extension.dart';

class SelectOptionTextField extends StatefulWidget {
  final TextfieldTagsController tagController;
  final List<SelectOptionPB> options;
  final LinkedHashMap<String, SelectOptionPB> selectedOptionMap;
  final double distanceToText;
  final List<String> textSeparators;

  final Function(String) onSubmitted;
  final Function(String) newText;
  final Function(List<String>, String) onPaste;
  final Function(String) onRemove;
  final VoidCallback? onClick;
  final int? maxLength;

  const SelectOptionTextField({
    required this.options,
    required this.selectedOptionMap,
    required this.distanceToText,
    required this.tagController,
    required this.onSubmitted,
    required this.onPaste,
    required this.onRemove,
    required this.newText,
    required this.textSeparators,
    this.onClick,
    this.maxLength,
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

  String? _suffixText() {
    if (widget.maxLength != null) {
      return ' ${controller.text.length}/${widget.maxLength}';
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFieldTags(
      textEditingController: controller,
      textfieldTagsController: widget.tagController,
      initialTags: widget.selectedOptionMap.keys.toList(),
      focusNode: focusNode,
      textSeparators: widget.textSeparators,
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
              _newText(text, editController);
            },
            onSubmitted: (text) {
              if (onSubmitted != null) {
                onSubmitted(text);
              }

              if (text.isNotEmpty) {
                widget.onSubmitted(text.trim());
                focusNode.requestFocus();
              }
            },
            maxLines: 1,
            maxLength: widget.maxLength,
            maxLengthEnforcement:
                MaxLengthEnforcement.truncateAfterCompositionEnds,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1.0,
                ),
                borderRadius: Corners.s10Border,
              ),
              isDense: true,
              prefixIcon: _renderTags(context, sc),
              hintText: LocaleKeys.grid_selectOption_searchOption.tr(),
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Theme.of(context).hintColor),
              suffixText: _suffixText(),
              counterText: "",
              prefixIconConstraints:
                  BoxConstraints(maxWidth: widget.distanceToText),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
                borderRadius: Corners.s10Border,
              ),
            ),
          );
        });
      },
    );
  }

  void _newText(String text, TextEditingController editingController) {
    if (text.isEmpty) {
      widget.newText('');
      return;
    }

    final result = splitInput(text.trimLeft(), widget.textSeparators);

    editingController.text = result[1];
    editingController.selection =
        TextSelection.collapsed(offset: controller.text.length);
    widget.onPaste(result[0], result[1]);
  }

  Widget? _renderTags(BuildContext context, ScrollController sc) {
    if (widget.selectedOptionMap.isEmpty) {
      return null;
    }

    final children = widget.selectedOptionMap.values
        .map(
          (option) => SelectOptionTag(
            option: option,
            onRemove: (option) => widget.onRemove(option),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          ),
        )
        .toList();
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
            },
          ),
          child: SingleChildScrollView(
            controller: sc,
            scrollDirection: Axis.horizontal,
            child: Wrap(spacing: 4, children: children),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
List splitInput(String input, List<String> textSeparators) {
  final List<String> splits = [];
  String currentString = '';

  // split the string into tokens
  for (final char in input.split('')) {
    if (textSeparators.contains(char)) {
      if (currentString.trim().isNotEmpty) {
        splits.add(currentString.trim());
      }
      currentString = '';
      continue;
    }
    currentString += char;
  }
  // add the remainder (might be '')
  splits.add(currentString);

  final submittedOptions = splits.sublist(0, splits.length - 1).toList();
  final remainder = splits.elementAt(splits.length - 1).trimLeft();

  return [submittedOptions, remainder];
}

import 'dart:collection';

import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'extension.dart';

class SelectOptionTextField extends StatefulWidget {
  const SelectOptionTextField({
    super.key,
    required this.options,
    required this.selectedOptionMap,
    required this.distanceToText,
    required this.textSeparators,
    required this.textController,
    required this.focusNode,
    required this.onSubmitted,
    required this.newText,
    required this.onPaste,
    required this.onRemove,
    this.scrollController,
    this.onClick,
  });

  final List<SelectOptionPB> options;
  final LinkedHashMap<String, SelectOptionPB> selectedOptionMap;
  final double distanceToText;
  final List<String> textSeparators;
  final TextEditingController textController;
  final ScrollController? scrollController;
  final FocusNode focusNode;

  final Function() onSubmitted;
  final Function(String) newText;
  final Function(List<String>, String) onPaste;
  final Function(String) onRemove;
  final VoidCallback? onClick;

  @override
  State<SelectOptionTextField> createState() => _SelectOptionTextFieldState();
}

class _SelectOptionTextFieldState extends State<SelectOptionTextField> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusNode.requestFocus();
      _scrollToEnd();
    });
    widget.textController.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    if (oldWidget.selectedOptionMap.length < widget.selectedOptionMap.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.textController,
      focusNode: widget.focusNode,
      onTap: widget.onClick,
      onSubmitted: (_) => widget.onSubmitted(),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          borderRadius: Corners.s10Border,
        ),
        isDense: true,
        prefixIcon: _renderTags(context),
        prefixIconConstraints: BoxConstraints(maxWidth: widget.distanceToText),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          borderRadius: Corners.s10Border,
        ),
      ),
    );
  }

  void _scrollToEnd() {
    if (widget.scrollController?.hasClients ?? false) {
      widget.scrollController?.animateTo(
        widget.scrollController!.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void _onChanged() {
    if (!widget.textController.value.composing.isCollapsed) {
      return;
    }

    // split input
    final (submitted, remainder) = splitInput(
      widget.textController.text.trimLeft(),
      widget.textSeparators,
    );

    if (submitted.isNotEmpty) {
      widget.textController.text = remainder;
      widget.textController.selection =
          TextSelection.collapsed(offset: widget.textController.text.length);
    }
    widget.onPaste(submitted, remainder);
  }

  Widget? _renderTags(BuildContext context) {
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

    return Focus(
      descendantsAreFocusable: false,
      child: MouseRegion(
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
              scrollDirection: Axis.horizontal,
              controller: widget.scrollController,
              child: Wrap(spacing: 4, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
(List<String>, String) splitInput(String input, List<String> textSeparators) {
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

  return (submittedOptions, remainder);
}

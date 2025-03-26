import 'package:appflowy/plugins/document/presentation/editor_plugins/base/markdown_text_robot.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:numerus/roman/roman.dart';

class NumberedListIcon extends StatelessWidget {
  const NumberedListIcon({
    super.key,
    required this.node,
    required this.textDirection,
    this.textStyle,
  });

  final Node node;
  final TextDirection textDirection;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final textStyleConfiguration =
        context.read<EditorState>().editorStyle.textStyleConfiguration;
    final height =
        textStyleConfiguration.text.height ?? textStyleConfiguration.lineHeight;
    final combinedTextStyle = textStyle?.combine(textStyleConfiguration.text) ??
        textStyleConfiguration.text;
    final adjustedTextStyle = combinedTextStyle.copyWith(
      height: height,
      fontFeatures: [const FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.only(left: 6.0, right: 10.0),
      child: Text(
        node.buildLevelString(context),
        style: adjustedTextStyle,
        strutStyle: StrutStyle.fromTextStyle(combinedTextStyle),
        textHeightBehavior: TextHeightBehavior(
          applyHeightToFirstAscent:
              textStyleConfiguration.applyHeightToFirstAscent,
          applyHeightToLastDescent:
              textStyleConfiguration.applyHeightToLastDescent,
          leadingDistribution: textStyleConfiguration.leadingDistribution,
        ),
        textDirection: textDirection,
      ),
    );
  }
}

extension NumberedListNodeIndex on Node {
  String buildLevelString(BuildContext context) {
    final builder = NumberedListIndexBuilder(
      editorState: context.read<EditorState>(),
      node: this,
    );
    final indexInRootLevel = builder.indexInRootLevel;
    final indexInSameLevel = builder.indexInSameLevel;
    final level = indexInRootLevel % 3;
    final levelString = switch (level) {
      1 => indexInSameLevel.latin,
      2 => indexInSameLevel.roman,
      _ => '$indexInSameLevel',
    };
    return '$levelString.';
  }
}

class NumberedListIndexBuilder {
  NumberedListIndexBuilder({
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  // the level of the current node
  int get indexInRootLevel {
    var level = 0;
    var parent = node.parent;
    while (parent != null) {
      if (parent.type == NumberedListBlockKeys.type) {
        level++;
      }
      parent = parent.parent;
    }
    return level;
  }

  // the index of the current level
  int get indexInSameLevel {
    int level = 1;
    Node? previous = node.previous;

    // if the previous one is not a numbered list, then it is the first one
    final aiNodeExternalValues =
        node.externalValues?.unwrapOrNull<AINodeExternalValues>();

    if (previous == null ||
        previous.type != NumberedListBlockKeys.type ||
        (aiNodeExternalValues != null &&
            aiNodeExternalValues.isFirstNumberedListNode)) {
      return node.attributes[NumberedListBlockKeys.number] ?? level;
    }

    int? startNumber;
    while (previous != null && previous.type == NumberedListBlockKeys.type) {
      startNumber = previous.attributes[NumberedListBlockKeys.number] as int?;
      level++;
      previous = previous.previous;

      // break the loop if the start number is found when the current node is an AI node
      if (aiNodeExternalValues != null && startNumber != null) {
        return startNumber + level - 1;
      }
    }

    if (startNumber != null) {
      level = startNumber + level - 1;
    }

    return level;
  }
}

extension on int {
  String get latin {
    String result = '';
    int number = this;
    while (number > 0) {
      final int remainder = (number - 1) % 26;
      result = String.fromCharCode(remainder + 65) + result;
      number = (number - 1) ~/ 26;
    }
    return result.toLowerCase();
  }

  String get roman {
    return toRomanNumeralString() ?? '$this';
  }
}

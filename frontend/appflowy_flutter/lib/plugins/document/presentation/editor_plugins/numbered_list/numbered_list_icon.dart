import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:numerus/roman/roman.dart';

class NumberedListIcon extends StatelessWidget {
  const NumberedListIcon({
    super.key,
    required this.node,
    required this.textDirection,
  });

  final Node node;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        context.read<EditorState>().editorStyle.textStyleConfiguration.text;
    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      margin: const EdgeInsets.only(right: 8.0),
      alignment: Alignment.center,
      child: Center(
        child: Text(
          node.levelString,
          style: textStyle,
          textDirection: textDirection,
        ),
      ),
    );
  }
}

extension on Node {
  String get levelString {
    final builder = _NumberedListIconBuilder(node: this);
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

class _NumberedListIconBuilder {
  _NumberedListIconBuilder({
    required this.node,
  });

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
    if (previous == null || previous.type != NumberedListBlockKeys.type) {
      return node.attributes[NumberedListBlockKeys.number] ?? level;
    }

    int? startNumber;
    while (previous != null && previous.type == NumberedListBlockKeys.type) {
      startNumber = previous.attributes[NumberedListBlockKeys.number] as int?;
      level++;
      previous = previous.previous;
    }
    if (startNumber != null) {
      return startNumber + level - 1;
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

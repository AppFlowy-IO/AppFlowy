import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../model/document/node/block.dart';
import '../model/document/node/line.dart';
import '../model/document/attribute.dart';
import '../rendering/text_block.dart';
import '../service/cursor.dart';
import '../service/style.dart';
import '../widget/text_line.dart';
import '../widget/proxy.dart';

/* --------------------------------- Widget --------------------------------- */

class EditableTextBlock extends StatelessWidget {
  const EditableTextBlock(
    this.block,
    this.textDirection,
    this.textSelection,
    this.scrollBottomInset,
    this.verticalSpacing,
    this.color,
    this.styles,
    this.enableInteractiveSelection,
    this.hasFocus,
    this.contentPadding,
    this.embedBuilder,
    this.cursorController,
    this.indentLevelCounts,
  );

  final Block block;
  final TextDirection textDirection;
  final TextSelection textSelection;
  final double scrollBottomInset;
  final Tuple2 verticalSpacing;
  final Color color;
  final DefaultStyles? styles;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets? contentPadding;
  final EmbedBuilderFuncion embedBuilder;
  final CursorController cursorController;
  final Map<int, int> indentLevelCounts;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final defaultStyle = EditorStyles.getStyles(context, false);
    return _EditableBlock(
      block,
      textDirection,
      verticalSpacing as Tuple2<double, double>,
      scrollBottomInset,
      _getDecorationForBlock(block, defaultStyle) ?? const BoxDecoration(),
      contentPadding,
      _buildChildren(context, indentLevelCounts),
    );
  }

  // Builder
  BoxDecoration? _getDecorationForBlock(
      Block node, DefaultStyles? defaultStyles) {
    final attrs = block.style.attributes;
    if (attrs.containsKey(Attribute.quoteBlock.key)) {
      return defaultStyles!.quote!.decoration;
    } else if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.decoration;
    }
    return null;
  }

  List<Widget> _buildChildren(
      BuildContext context, Map<int, int> indentLevelCounts) {
    final defaultStyles = EditorStyles.getStyles(context, false);
    final count = block.children.length;
    final children = <Widget>[];
    var index = 0;
    for (final line in Iterable.castFrom<dynamic, Line>(block.children)) {
      index++;
      final editableTextLine = EditableTextLine(
        line,
        _buildLeading(context, line, index, indentLevelCounts, count),
        TextLine(
          line: line,
          textDirection: textDirection,
          embedBuilder: embedBuilder,
          styles: styles!,
        ),
        _getIndentWidth(),
        _getSpacingForLine(line, index, count, defaultStyles),
        textDirection,
        textSelection,
        color,
        enableInteractiveSelection,
        hasFocus,
        MediaQuery.of(context).devicePixelRatio,
        cursorController,
      );
      children.add(editableTextLine);
    }
    return children.toList(growable: false);
  }

  double _getIndentWidth() {
    final attrs = block.style.attributes;

    final indent = attrs[Attribute.indent.key];
    var extraIndent = 0.0;
    if (indent != null && indent.value != null) {
      extraIndent = 16.0 * indent.value;
    }

    if (attrs.containsKey(Attribute.quoteBlock.key)) {
      return 16.0 + extraIndent;
    }

    return 32.0 + extraIndent;
  }

  Widget? _buildLeading(BuildContext context, Line line, int index,
      Map<int, int> indentLevelCounts, int count) {
    final defaultStyles = EditorStyles.getStyles(context, false);
    final attrs = line.style.attributes;

    // List Type (OrderedList, BulletList, CheckedList)
    if (attrs[Attribute.list.key] == Attribute.ordered) {
      return _NumberPoint(
        index: index,
        indentLevelCounts: indentLevelCounts,
        count: count,
        style: defaultStyles!.leading!.style,
        attrs: attrs,
        width: 32,
        padding: 8,
      );
    } else if (attrs[Attribute.list.key] == Attribute.bullet) {
      return _BulletPoint(
        style:
            defaultStyles!.leading!.style.copyWith(fontWeight: FontWeight.bold),
        width: 32,
      );
    } else if (attrs[Attribute.list.key] == Attribute.checked) {
      return _Checkbox(
        style: defaultStyles!.leading!.style,
        width: 32,
        isChecked: true,
      );
    } else if (attrs[Attribute.list.key] == Attribute.unchecked) {
      return _Checkbox(
        style: defaultStyles!.leading!.style,
        width: 32,
        isChecked: false,
      );
    }

    // Code Block
    if (attrs.containsKey(Attribute.codeBlock.key)) {
      return _NumberPoint(
        index: index,
        indentLevelCounts: indentLevelCounts,
        count: count,
        style: defaultStyles!.code!.style
            .copyWith(color: defaultStyles.code!.style.color!.withOpacity(0.4)),
        width: 32,
        padding: 16,
        withDot: false,
        attrs: attrs,
      );
    }

    return null;
  }

  Tuple2 _getSpacingForLine(
      Line node, int index, int count, DefaultStyles? defaultStyles) {
    var top = 0.0, bottom = 0.0;

    final attrs = block.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      final level = attrs[Attribute.header.key]!.value;
      final headerStyles = <int, DefaultTextBlockStyle>{
        1: defaultStyles!.h1!,
        2: defaultStyles.h2!,
        3: defaultStyles.h3!,
        4: defaultStyles.h4!,
        5: defaultStyles.h5!,
        6: defaultStyles.h6!,
      };
      if (!headerStyles.containsKey(level)) {
        throw 'Invalid level $level';
      }

      top = headerStyles[level]!.verticalSpacing.item1;
      bottom = headerStyles[level]!.verticalSpacing.item2;
    } else {
      Tuple2? lineSpacing;
      final blockStyles = <String, DefaultTextBlockStyle>{
        Attribute.quoteBlock.key: defaultStyles!.quote!,
        Attribute.indent.key: defaultStyles.indent!,
        Attribute.list.key: defaultStyles.lists!,
        Attribute.codeBlock.key: defaultStyles.code!,
        Attribute.align.key: defaultStyles.align!,
      };
      blockStyles.forEach((k, v) {
        if (attrs.containsKey(k) && lineSpacing != null) {
          lineSpacing = v.lineSpacing;
        }
      });
      top = lineSpacing?.item1 ?? top;
      bottom = lineSpacing?.item2 ?? bottom;
    }

    // remove first and last edge padding
    if (index == 1) {
      top = 0.0;
    }
    if (index == count) {
      bottom = 0.0;
    }

    return Tuple2(top, bottom);
  }
}

/* ------------------------ Multi Child RenderObject ------------------------ */

class _EditableBlock extends MultiChildRenderObjectWidget {
  _EditableBlock(
    this.block,
    this.textDirection,
    this.padding,
    this.scrollBottomInset,
    this.decoration,
    this.contentPadding,
    List<Widget> children,
  ) : super(children: children);

  final Block block;
  final TextDirection textDirection;
  final Tuple2<double, double> padding;
  final double scrollBottomInset;
  final Decoration decoration;
  final EdgeInsets? contentPadding;

  EdgeInsets get _padding =>
      EdgeInsets.only(top: padding.item1, bottom: padding.item2);

  EdgeInsets get _contentPadding => contentPadding ?? EdgeInsets.zero;

  @override
  RenderEditableTextBlock createRenderObject(BuildContext context) {
    return RenderEditableTextBlock(
      block: block,
      textDirection: textDirection,
      padding: _padding,
      scrollBottomInset: scrollBottomInset,
      decoration: decoration,
      contentPadding: _contentPadding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextBlock renderObject) {
    renderObject
      ..container = block
      ..textDirection = textDirection
      ..scrollBottomInset = scrollBottomInset
      ..padding = _padding
      ..decoration = decoration
      ..contentPadding = _contentPadding;
  }
}

/* ------------------------- Block Supplement Widget ------------------------ */

const List<int> arabianRomanNumbers = [
  1000,
  900,
  500,
  400,
  100,
  90,
  50,
  40,
  10,
  9,
  5,
  4,
  1
];

const List<String> romanNumbers = [
  'M',
  'CM',
  'D',
  'CD',
  'C',
  'XC',
  'L',
  'XL',
  'X',
  'IX',
  'V',
  'IV',
  'I'
];

class _NumberPoint extends StatelessWidget {
  const _NumberPoint({
    required this.index,
    required this.indentLevelCounts,
    required this.count,
    required this.style,
    required this.width,
    required this.attrs,
    this.withDot = true,
    this.padding = 0.0,
    Key? key,
  }) : super(key: key);

  final int index;
  final Map<int?, int> indentLevelCounts;
  final int count;
  final TextStyle style;
  final double width;
  final Map<String, Attribute> attrs;
  final bool withDot;
  final double padding;

  @override
  Widget build(BuildContext context) {
    var s = index.toString();
    int? level = 0;
    if (!attrs.containsKey(Attribute.indent.key) &&
        !indentLevelCounts.containsKey(1)) {
      indentLevelCounts.clear();
      return Container(
        alignment: AlignmentDirectional.topEnd,
        width: width,
        padding: EdgeInsetsDirectional.only(end: padding),
        child: Text(withDot ? '$s.' : s, style: style),
      );
    }
    if (attrs.containsKey(Attribute.indent.key)) {
      level = attrs[Attribute.indent.key]!.value;
    } else {
      // first level but is back from previous indent level
      // supposed to be "2."
      indentLevelCounts[0] = 1;
    }
    if (indentLevelCounts.containsKey(level! + 1)) {
      // last visited level is done, going up
      indentLevelCounts.remove(level + 1);
    }
    final count = (indentLevelCounts[level] ?? 0) + 1;
    indentLevelCounts[level] = count;

    s = count.toString();
    if (level % 3 == 1) {
      // a. b. c. d. e. ...
      s = _toExcelSheetColumnTitle(count);
    } else if (level % 3 == 2) {
      // i. ii. iii. ...
      s = _intToRoman(count);
    }
    // level % 3 == 0 goes back to 1. 2. 3.

    return Container(
      alignment: AlignmentDirectional.topEnd,
      width: width,
      padding: EdgeInsetsDirectional.only(end: padding),
      child: Text(withDot ? '$s.' : s, style: style),
    );
  }

  String _toExcelSheetColumnTitle(int n) {
    final result = StringBuffer();
    while (n > 0) {
      n--;
      result.write(String.fromCharCode((n % 26).floor() + 97));
      n = (n / 26).floor();
    }

    return result.toString().split('').reversed.join();
  }

  String _intToRoman(int input) {
    var num = input;

    if (num < 0) {
      return '';
    } else if (num == 0) {
      return 'nulla';
    }

    final builder = StringBuffer();
    for (var a = 0; a < arabianRomanNumbers.length; a++) {
      final times = (num / arabianRomanNumbers[a])
          .truncate(); // equals 1 only when arabianRomanNumbers[a] = num
      // executes n times where n is the number of times you have to add
      // the current roman number value to reach current num.
      builder.write(romanNumbers[a] * times);
      num -= times *
          arabianRomanNumbers[
              a]; // subtract previous roman number value from num
    }

    return builder.toString().toLowerCase();
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({
    required this.style,
    required this.width,
    Key? key,
  }) : super(key: key);

  final TextStyle style;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topEnd,
      width: width,
      padding: const EdgeInsetsDirectional.only(end: 13),
      child: Text('•', style: style),
    );
  }
}

class _Checkbox extends StatefulWidget {
  const _Checkbox({
    Key? key,
    this.style,
    this.width,
    this.isChecked,
    this.onChanged,
  }) : super(key: key);

  final TextStyle? style;
  final double? width;
  final bool? isChecked;
  final Function(bool?)? onChanged;

  @override
  __CheckboxState createState() => __CheckboxState();
}

class __CheckboxState extends State<_Checkbox> {
  bool? isChecked;

  void _onCheckboxChanged(bool? newValue) {
    setState(() {
      isChecked = newValue;
      if (widget.onChanged != null) {
        widget.onChanged!(isChecked);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    isChecked = widget.isChecked;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topEnd,
      width: widget.width,
      padding: const EdgeInsetsDirectional.only(end: 13),
      child: Checkbox(
        value: widget.isChecked,
        onChanged: _onCheckboxChanged,
      ),
    );
  }
}

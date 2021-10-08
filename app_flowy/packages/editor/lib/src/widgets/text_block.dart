import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tuple/tuple.dart';

import '../models/documents/attribute.dart';
import '../models/documents/nodes/block.dart';
import '../models/documents/nodes/line.dart';
import 'box.dart';
import 'cursor.dart';
import 'default_styles.dart';
import 'delegate.dart';
import 'editor.dart';
import 'text_line.dart';
import 'text_selection.dart';

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

class EditableTextBlock extends StatelessWidget {
  const EditableTextBlock(
      {required this.block,
      required this.textDirection,
      required this.scrollBottomInset,
      required this.verticalSpacing,
      required this.textSelection,
      required this.color,
      required this.styles,
      required this.enableInteractiveSelection,
      required this.hasFocus,
      required this.contentPadding,
      required this.embedBuilder,
      required this.cursorCont,
      required this.indentLevelCounts,
      required this.onCheckboxTap,
      required this.readOnly,
      this.customStyleBuilder,
      Key? key});

  final Block block;
  final TextDirection textDirection;
  final double scrollBottomInset;
  final Tuple2 verticalSpacing;
  final TextSelection textSelection;
  final Color color;
  final DefaultStyles? styles;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets? contentPadding;
  final EmbedBuilder embedBuilder;
  final CustomStyleBuilder? customStyleBuilder;
  final CursorCont cursorCont;
  final Map<int, int> indentLevelCounts;
  final Function(int, bool) onCheckboxTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final defaultStyles = QuillStyles.getStyles(context, false);
    return _EditableBlock(
        block,
        textDirection,
        verticalSpacing as Tuple2<double, double>,
        scrollBottomInset,
        _getDecorationForBlock(block, defaultStyles) ?? const BoxDecoration(),
        contentPadding,
        _buildChildren(context, indentLevelCounts));
  }

  BoxDecoration? _getDecorationForBlock(
      Block node, DefaultStyles? defaultStyles) {
    final attrs = block.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return defaultStyles!.quote!.decoration;
    }
    if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.decoration;
    }
    return null;
  }

  List<Widget> _buildChildren(
      BuildContext context, Map<int, int> indentLevelCounts) {
    final defaultStyles = QuillStyles.getStyles(context, false);
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
            customStyleBuilder: customStyleBuilder,
            styles: styles!,
            readOnly: readOnly,
          ),
          _getIndentWidth(),
          _getSpacingForLine(line, index, count, defaultStyles),
          textDirection,
          textSelection,
          color,
          enableInteractiveSelection,
          hasFocus,
          MediaQuery.of(context).devicePixelRatio,
          cursorCont);
      children.add(editableTextLine);
    }
    return children.toList(growable: false);
  }

  Widget? _buildLeading(BuildContext context, Line line, int index,
      Map<int, int> indentLevelCounts, int count) {
    final defaultStyles = QuillStyles.getStyles(context, false);
    final attrs = line.style.attributes;
    if (attrs[Attribute.list.key] == Attribute.ol) {
      return _NumberPoint(
        index: index,
        indentLevelCounts: indentLevelCounts,
        count: count,
        style: defaultStyles!.leading!.style,
        attrs: attrs,
        width: 32,
        padding: 8,
      );
    }

    if (attrs[Attribute.list.key] == Attribute.ul) {
      return _BulletPoint(
        style:
            defaultStyles!.leading!.style.copyWith(fontWeight: FontWeight.bold),
        width: 32,
      );
    }

    if (attrs[Attribute.list.key] == Attribute.checked) {
      return _Checkbox(
        key: UniqueKey(),
        style: defaultStyles!.leading!.style,
        width: 32,
        isChecked: true,
        offset: block.offset + line.offset,
        onTap: onCheckboxTap,
      );
    }

    if (attrs[Attribute.list.key] == Attribute.unchecked) {
      return _Checkbox(
        key: UniqueKey(),
        style: defaultStyles!.leading!.style,
        width: 32,
        offset: block.offset + line.offset,
        onTap: onCheckboxTap,
      );
    }

    if (attrs.containsKey(Attribute.codeBlock.key)) {
      return _NumberPoint(
        index: index,
        indentLevelCounts: indentLevelCounts,
        count: count,
        style: defaultStyles!.code!.style
            .copyWith(color: defaultStyles.code!.style.color!.withOpacity(0.4)),
        width: 32,
        attrs: attrs,
        padding: 16,
        withDot: false,
      );
    }
    return null;
  }

  double _getIndentWidth() {
    final attrs = block.style.attributes;

    final indent = attrs[Attribute.indent.key];
    var extraIndent = 0.0;
    if (indent != null && indent.value != null) {
      extraIndent = 16.0 * indent.value;
    }

    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return 16.0 + extraIndent;
    }

    var baseIndent = 0.0;

    if (attrs.containsKey(Attribute.list.key) ||
        attrs.containsKey(Attribute.codeBlock.key)) {
      baseIndent = 32.0;
    }

    return baseIndent + extraIndent;
  }

  Tuple2 _getSpacingForLine(
      Line node, int index, int count, DefaultStyles? defaultStyles) {
    var top = 0.0, bottom = 0.0;

    final attrs = block.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      final level = attrs[Attribute.header.key]!.value;
      switch (level) {
        case 1:
          top = defaultStyles!.h1!.verticalSpacing.item1;
          bottom = defaultStyles.h1!.verticalSpacing.item2;
          break;
        case 2:
          top = defaultStyles!.h2!.verticalSpacing.item1;
          bottom = defaultStyles.h2!.verticalSpacing.item2;
          break;
        case 3:
          top = defaultStyles!.h3!.verticalSpacing.item1;
          bottom = defaultStyles.h3!.verticalSpacing.item2;
          break;
        default:
          throw 'Invalid level $level';
      }
    } else {
      late Tuple2 lineSpacing;
      if (attrs.containsKey(Attribute.blockQuote.key)) {
        lineSpacing = defaultStyles!.quote!.lineSpacing;
      } else if (attrs.containsKey(Attribute.indent.key)) {
        lineSpacing = defaultStyles!.indent!.lineSpacing;
      } else if (attrs.containsKey(Attribute.list.key)) {
        lineSpacing = defaultStyles!.lists!.lineSpacing;
      } else if (attrs.containsKey(Attribute.codeBlock.key)) {
        lineSpacing = defaultStyles!.code!.lineSpacing;
      } else if (attrs.containsKey(Attribute.align.key)) {
        lineSpacing = defaultStyles!.align!.lineSpacing;
      }
      top = lineSpacing.item1;
      bottom = lineSpacing.item2;
    }

    if (index == 1) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return Tuple2(top, bottom);
  }
}

class RenderEditableTextBlock extends RenderEditableContainerBox
    implements RenderEditableBox {
  RenderEditableTextBlock({
    required Block block,
    required TextDirection textDirection,
    required EdgeInsetsGeometry padding,
    required double scrollBottomInset,
    required Decoration decoration,
    List<RenderEditableBox>? children,
    ImageConfiguration configuration = ImageConfiguration.empty,
    EdgeInsets contentPadding = EdgeInsets.zero,
  })  : _decoration = decoration,
        _configuration = configuration,
        _savedPadding = padding,
        _contentPadding = contentPadding,
        super(
          children,
          block,
          textDirection,
          scrollBottomInset,
          padding.add(contentPadding),
        );

  EdgeInsetsGeometry _savedPadding;
  EdgeInsets _contentPadding;

  set contentPadding(EdgeInsets value) {
    if (_contentPadding == value) return;
    _contentPadding = value;
    super.setPadding(_savedPadding.add(_contentPadding));
  }

  @override
  void setPadding(EdgeInsetsGeometry value) {
    super.setPadding(value.add(_contentPadding));
    _savedPadding = value;
  }

  BoxPainter? _painter;

  Decoration get decoration => _decoration;
  Decoration _decoration;

  set decoration(Decoration value) {
    if (value == _decoration) return;
    _painter?.dispose();
    _painter = null;
    _decoration = value;
    markNeedsPaint();
  }

  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;

  set configuration(ImageConfiguration value) {
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    final child = childAtPosition(position);
    final rangeInChild = child.getLineBoundary(TextPosition(
      offset: position.offset - child.getContainer().offset,
      affinity: position.affinity,
    ));
    return TextRange(
      start: rangeInChild.start + child.getContainer().offset,
      end: rangeInChild.end + child.getContainer().offset,
    );
  }

  @override
  Offset getOffsetForCaret(TextPosition position) {
    final child = childAtPosition(position);
    return child.getOffsetForCaret(TextPosition(
          offset: position.offset - child.getContainer().offset,
          affinity: position.affinity,
        )) +
        (child.parentData as BoxParentData).offset;
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final child = childAtOffset(offset)!;
    final parentData = child.parentData as BoxParentData;
    final localPosition =
        child.getPositionForOffset(offset - parentData.offset);
    return TextPosition(
      offset: localPosition.offset + child.getContainer().offset,
      affinity: localPosition.affinity,
    );
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    final child = childAtPosition(position);
    final nodeOffset = child.getContainer().offset;
    final childWord = child
        .getWordBoundary(TextPosition(offset: position.offset - nodeOffset));
    return TextRange(
      start: childWord.start + nodeOffset,
      end: childWord.end + nodeOffset,
    );
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    assert(position.offset < getContainer().length);

    final child = childAtPosition(position);
    final childLocalPosition =
        TextPosition(offset: position.offset - child.getContainer().offset);
    final result = child.getPositionAbove(childLocalPosition);
    if (result != null) {
      return TextPosition(offset: result.offset + child.getContainer().offset);
    }

    final sibling = childBefore(child);
    if (sibling == null) {
      return null;
    }

    final caretOffset = child.getOffsetForCaret(childLocalPosition);
    final testPosition =
        TextPosition(offset: sibling.getContainer().length - 1);
    final testOffset = sibling.getOffsetForCaret(testPosition);
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);
    return TextPosition(
        offset: sibling.getContainer().offset +
            sibling.getPositionForOffset(finalOffset).offset);
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    assert(position.offset < getContainer().length);

    final child = childAtPosition(position);
    final childLocalPosition =
        TextPosition(offset: position.offset - child.getContainer().offset);
    final result = child.getPositionBelow(childLocalPosition);
    if (result != null) {
      return TextPosition(offset: result.offset + child.getContainer().offset);
    }

    final sibling = childAfter(child);
    if (sibling == null) {
      return null;
    }

    final caretOffset = child.getOffsetForCaret(childLocalPosition);
    final testOffset = sibling.getOffsetForCaret(const TextPosition(offset: 0));
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);
    return TextPosition(
        offset: sibling.getContainer().offset +
            sibling.getPositionForOffset(finalOffset).offset);
  }

  @override
  double preferredLineHeight(TextPosition position) {
    final child = childAtPosition(position);
    return child.preferredLineHeight(
        TextPosition(offset: position.offset - child.getContainer().offset));
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      return TextSelectionPoint(
          Offset(0, preferredLineHeight(selection.extent)) +
              getOffsetForCaret(selection.extent),
          null);
    }

    final baseNode = getContainer().queryChild(selection.start, false).node;
    var baseChild = firstChild;
    while (baseChild != null) {
      if (baseChild.getContainer() == baseNode) {
        break;
      }
      baseChild = childAfter(baseChild);
    }
    assert(baseChild != null);

    final basePoint = baseChild!.getBaseEndpointForSelection(
        localSelection(baseChild.getContainer(), selection, true));
    return TextSelectionPoint(
        basePoint.point + (baseChild.parentData as BoxParentData).offset,
        basePoint.direction);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      return TextSelectionPoint(
          Offset(0, preferredLineHeight(selection.extent)) +
              getOffsetForCaret(selection.extent),
          null);
    }

    final extentNode = getContainer().queryChild(selection.end, false).node;

    var extentChild = firstChild;
    while (extentChild != null) {
      if (extentChild.getContainer() == extentNode) {
        break;
      }
      extentChild = childAfter(extentChild);
    }
    assert(extentChild != null);

    final extentPoint = extentChild!.getExtentEndpointForSelection(
        localSelection(extentChild.getContainer(), selection, true));
    return TextSelectionPoint(
        extentPoint.point + (extentChild.parentData as BoxParentData).offset,
        extentPoint.direction);
  }

  @override
  void detach() {
    _painter?.dispose();
    _painter = null;
    super.detach();
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintDecoration(context, offset);
    defaultPaint(context, offset);
  }

  void _paintDecoration(PaintingContext context, Offset offset) {
    _painter ??= _decoration.createBoxPainter(markNeedsPaint);

    final decorationPadding = resolvedPadding! - _contentPadding;

    final filledConfiguration =
        configuration.copyWith(size: decorationPadding.deflateSize(size));
    final debugSaveCount = context.canvas.getSaveCount();

    final decorationOffset =
        offset.translate(decorationPadding.left, decorationPadding.top);
    _painter!.paint(context.canvas, decorationOffset, filledConfiguration);
    if (debugSaveCount != context.canvas.getSaveCount()) {
      throw '${_decoration.runtimeType} painter had mismatching save and  '
          'restore calls.';
    }
    if (decoration.isComplex) {
      context.setIsComplexHint();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    final child = childAtPosition(position);
    final localPosition = TextPosition(
      offset: position.offset - child.getContainer().offset,
      affinity: position.affinity,
    );
    final parentData = child.parentData as BoxParentData;
    return child.getLocalRectForCaret(localPosition).shift(parentData.offset);
  }

  @override
  TextPosition globalToLocalPosition(TextPosition position) {
    assert(getContainer().containsOffset(position.offset),
        'The provided text position is not in the current node');
    return TextPosition(
      offset: position.offset - getContainer().documentOffset,
      affinity: position.affinity,
    );
  }
}

class _EditableBlock extends MultiChildRenderObjectWidget {
  _EditableBlock(
      this.block,
      this.textDirection,
      this.padding,
      this.scrollBottomInset,
      this.decoration,
      this.contentPadding,
      List<Widget> children)
      : super(children: children);

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
      ..setContainer(block)
      ..textDirection = textDirection
      ..scrollBottomInset = scrollBottomInset
      ..setPadding(_padding)
      ..decoration = decoration
      ..contentPadding = _contentPadding;
  }
}

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

class _Checkbox extends StatelessWidget {
  const _Checkbox({
    Key? key,
    this.style,
    this.width,
    this.isChecked = false,
    this.offset,
    this.onTap,
  }) : super(key: key);
  final TextStyle? style;
  final double? width;
  final bool isChecked;
  final int? offset;
  final Function(int, bool)? onTap;

  void _onCheckboxClicked(bool? newValue) {
    if (onTap != null && newValue != null && offset != null) {
      onTap!(offset!, newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topEnd,
      width: width,
      padding: const EdgeInsetsDirectional.only(end: 13),
      child: GestureDetector(
        onLongPress: () => _onCheckboxClicked(!isChecked),
        child: Checkbox(
          value: isChecked,
          onChanged: _onCheckboxClicked,
        ),
      ),
    );
  }
}

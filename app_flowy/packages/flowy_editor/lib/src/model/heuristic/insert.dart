import 'package:tuple/tuple.dart';

import '../quill_delta.dart';
import '../document/style.dart';
import '../document/attribute.dart';
import 'rule.dart';

abstract class InsertRule extends Rule {
  const InsertRule();

  @override
  RuleType get type => RuleType.INSERT;

  @override
  void validateArgs(int? length, Object? data, Attribute? attribute) {
    assert(data != null);
    assert(attribute == null);
  }
}

/* -------------------------------- Rule Impl ------------------------------- */

class PreserveLineStyleOnSplitRule extends InsertRule {
  const PreserveLineStyleOnSplitRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (data is! String || data != '\n') {
      return null;
    }

    final it = DeltaIterator(document);
    final before = it.skip(index);
    if (before == null ||
        before.data is! String ||
        (before.data as String).endsWith('\n')) {
      return null;
    }
    final after = it.next();
    if (after.data is! String || (after.data as String).startsWith('\n')) {
      return null;
    }

    final text = after.data as String;
    final delta = Delta()..retain(index + (length ?? 0));
    if (text.contains('\n')) {
      assert(after.isPlain);
      delta.insert('\n');
      return delta;
    }

    final nextNewLine = _getNextNewLine(it);
    final attributes = nextNewLine.item1?.attributes;

    return delta..insert('\n', attributes);
  }
}

class PreserveBlockStyleOnInsertRule extends InsertRule {
  const PreserveBlockStyleOnInsertRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (data is! String || !data.contains('\n')) {
      return null;
    }

    final it = DeltaIterator(document)..skip(index);

    final nextNewLine = _getNextNewLine(it);
    final lineStyle = Style.fromJson(
      nextNewLine.item1?.attributes ?? <String, dynamic>{},
    );

    final attribute = lineStyle.getBlockExceptHeader();
    if (attribute == null) {
      return null;
    }

    final blockStyle = <String, dynamic>{attribute.key: attribute.value};

    Map<String, dynamic>? resetStyle;

    if (lineStyle.containsKey(Attribute.header.key)) {
      resetStyle = Attribute.header.toJson();
    }

    final lines = data.split('\n');
    final delta = Delta()..retain(index + (length ?? 0));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isNotEmpty) {
        delta.insert(line);
      }
      if (i == 0) {
        delta.insert('\n', lineStyle.toJson());
      } else if (i < lines.length - 1) {
        delta.insert('\n', blockStyle);
      }
    }

    if (resetStyle != null) {
      delta
        ..retain(nextNewLine.item2!)
        ..retain((nextNewLine.item1!.data as String).indexOf('\n'))
        ..retain(1, resetStyle);
    }

    return delta;
  }
}

class AutoExitBlockRule extends InsertRule {
  const AutoExitBlockRule();

  bool _isEmptyLine(Operation? before, Operation? after) {
    if (before == null) {
      return true;
    }
    return before.data is String &&
        (before.data as String).endsWith('\n') &&
        after!.data is String &&
        (after.data as String).startsWith('\n');
  }

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (data is! String || data != '\n') {
      return null;
    }

    final it = DeltaIterator(document);
    final prev = it.skip(index), cur = it.next();
    final blockStyle = Style.fromJson(cur.attributes).getBlockExceptHeader();
    if (cur.isPlain || blockStyle == null) {
      return null;
    }
    if (!_isEmptyLine(prev, cur)) {
      return null;
    }

    if ((cur.value as String).length > 1) {
      return null;
    }

    final nextNewLine = _getNextNewLine(it);
    if (nextNewLine.item1 != null &&
        nextNewLine.item1!.attributes != null &&
        Style.fromJson(nextNewLine.item1!.attributes).getBlockExceptHeader() ==
            blockStyle) {
      return null;
    }

    final attributes = cur.attributes ?? <String, dynamic>{};
    final k = attributes.keys
        .firstWhere((k) => Attribute.blockKeysExceptHeader.contains(k));
    attributes[k] = null;
    // retain(1) should be '\n', set it with no attribute
    return Delta()..retain(index + (length ?? 0))..retain(1, attributes);
  }
}

class ResetLineFormatOnNewLineRule extends InsertRule {
  const ResetLineFormatOnNewLineRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (data is! String || data != '\n') {
      return null;
    }

    final itr = DeltaIterator(document)..skip(index);
    final cur = itr.next();
    if (cur.data is! String || !(cur.data as String).startsWith('\n')) {
      return null;
    }

    Map<String, dynamic>? resetStyle;
    if (cur.attributes != null &&
        cur.attributes!.containsKey(Attribute.header.key)) {
      resetStyle = Attribute.header.toJson();
    }
    return Delta()
      ..retain(index + (length ?? 0))
      ..insert('\n', cur.attributes)
      ..retain(1, resetStyle)
      ..trim();
  }
}

class InsertEmbedsRule extends InsertRule {
  const InsertEmbedsRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (data is String) {
      return null;
    }

    final delta = Delta()..retain(index + (length ?? 0));
    final it = DeltaIterator(document);
    final prev = it.skip(index), cur = it.next();

    final textBefore = prev?.data is String ? prev!.data as String? : '';
    final textAfter = cur.data is String ? (cur.data as String?)! : '';

    final isNewlineBefore = prev == null || textBefore!.endsWith('\n');
    final isNewlineAfter = textAfter.startsWith('\n');

    if (isNewlineBefore && isNewlineAfter) {
      return delta..insert(data);
    }

    Map<String, dynamic>? lineStyle;
    if (textAfter.contains('\n')) {
      lineStyle = cur.attributes;
    } else {
      while (it.hasNext) {
        final op = it.next();
        if ((op.data is String ? op.data as String? : '')!.contains('\n')) {
          lineStyle = op.attributes;
          break;
        }
      }
    }

    if (!isNewlineBefore) {
      delta.insert('\n', lineStyle);
    }
    delta.insert(data);
    if (!isNewlineAfter) {
      delta.insert('\n');
    }
    return delta;
  }
}

class ForceNewlineForInsertsAroundEmbedRule extends InsertRule {
  const ForceNewlineForInsertsAroundEmbedRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (data is! String) {
      return null;
    }

    final text = data;
    final it = DeltaIterator(document);
    final prev = it.skip(index), cur = it.next();
    final cursorBeforeEmbed = cur.data is! String;
    final cursorAfterEmbed = prev != null && prev.data is! String;

    if (!cursorBeforeEmbed && !cursorAfterEmbed) {
      return null;
    }
    final delta = Delta()..retain(index + (length ?? 0));
    if (cursorBeforeEmbed && !text.endsWith('\n')) {
      return delta..insert(text)..insert('\n');
    }
    if (cursorAfterEmbed && !text.startsWith('\n')) {
      return delta..insert('\n')..insert(text);
    }
    return delta..insert(text);
  }
}

class AutoFormatLinksRule extends InsertRule {
  const AutoFormatLinksRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (data is! String || data != ' ') {
      return null;
    }

    final it = DeltaIterator(document);
    final prev = it.skip(index);
    if (prev == null || prev.data is! String) {
      return null;
    }

    try {
      final cand = (prev.data as String).split('\n').last.split(' ').last;
      final link = Uri.parse(cand);
      if (!['https', 'http'].contains(link.scheme)) {
        return null;
      }
      final attributes = prev.attributes ?? <String, dynamic>{};

      if (attributes.containsKey(Attribute.link.key)) {
        return null;
      }

      attributes.addAll(LinkAttribute(link.toString()).toJson());
      return Delta()
        ..retain(index + (length ?? 0) - cand.length)
        ..retain(cand.length, attributes)
        ..insert(data, prev.attributes);
    } on FormatException {
      return null;
    }
  }
}

class PreserveInlineStylesRule extends InsertRule {
  const PreserveInlineStylesRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (data is! String || data.contains('\n')) {
      return null;
    }

    final it = DeltaIterator(document);
    final prev = it.skip(index);
    if (prev == null ||
        prev.data is! String ||
        (prev.data as String).contains('\n')) {
      return null;
    }

    final attributes = prev.attributes;
    final text = data;
    if (attributes == null || !attributes.containsKey(Attribute.link.key)) {
      return Delta()
        ..retain(index + (length ?? 0))
        ..insert(text, attributes);
    }

    attributes.remove(Attribute.link.key);
    final delta = Delta()
      ..retain(index + (length ?? 0))
      ..insert(text, attributes.isEmpty ? null : attributes);
    final next = it.next();

    final nextAttributes = next.attributes ?? const <String, dynamic>{};
    if (!nextAttributes.containsKey(Attribute.link.key)) {
      return delta;
    }
    if (attributes[Attribute.link.key] == nextAttributes[Attribute.link.key]) {
      return Delta()
        ..retain(index + (length ?? 0))
        ..insert(text, attributes);
    }
    return delta;
  }
}

class CatchAllInsertRule extends InsertRule {
  const CatchAllInsertRule();

  @override
  Delta applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    return Delta()
      ..retain(index + (length ?? 0))
      ..insert(data);
  }
}

/* --------------------------------- Helper --------------------------------- */

Tuple2<Operation?, int?> _getNextNewLine(DeltaIterator iterator) {
  Operation op;
  for (var skipped = 0; iterator.hasNext; skipped += op.length!) {
    op = iterator.next();
    final lineBreak =
        (op.data is String ? op.data as String? : '')!.indexOf('\n');
    if (lineBreak >= 0) {
      return Tuple2(op, skipped);
    }
  }
  return const Tuple2(null, null);
}

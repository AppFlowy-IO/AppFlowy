import '../quill_delta.dart';
import '../document/attribute.dart';
import 'rule.dart';

abstract class FormatRule extends Rule {
  const FormatRule();

  @override
  RuleType get type => RuleType.FORMAT;

  @override
  void validateArgs(int? length, Object? data, Attribute? attribute) {
    assert(length != null);
    assert(data == null);
    assert(attribute != null);
  }
}

/* -------------------------------- Rule Impl ------------------------------- */

class ResolveLineFormatRule extends FormatRule {
  const ResolveLineFormatRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (attribute!.scope != AttributeScope.BLOCK) {
      return null;
    }

    var delta = Delta()..retain(index);
    final it = DeltaIterator(document)..skip(index);
    Operation op;
    for (var cur = 0; cur < length! && it.hasNext; cur += op.length!) {
      op = it.next(length - cur);
      if (op.data is! String || !(op.data as String).contains('\n')) {
        delta.retain(op.length!);
        continue;
      }
      final text = op.data as String;
      final tmp = Delta();
      var offset = 0;

      for (var lineBreak = text.indexOf('\n');
          lineBreak >= 0;
          lineBreak = text.indexOf('\n', offset)) {
        tmp..retain(lineBreak - offset)..retain(1, attribute.toJson());
        offset = lineBreak + 1;
      }
      tmp.retain(text.length - offset);
      delta = delta.concat(tmp);
    }

    while (it.hasNext) {
      op = it.next();
      final text = op.data is String ? (op.data as String?)! : '';
      final lineBreak = text.indexOf('\n');
      if (lineBreak < 0) {
        delta.retain(op.length!);
        continue;
      }
      delta..retain(lineBreak)..retain(1, attribute.toJson());
      break;
    }
    return delta;
  }
}

class FormatLinkAtCaretPositionRule extends FormatRule {
  const FormatLinkAtCaretPositionRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (attribute!.key != Attribute.link.key || length! > 0) {
      return null;
    }

    final delta = Delta();
    final it = DeltaIterator(document);
    final before = it.skip(index), after = it.next();
    int? beg = index, retain = 0;
    if (before != null && before.hasAttribute(attribute.key)) {
      beg -= before.length!;
      retain = before.length;
    }
    if (after.hasAttribute(attribute.key)) {
      if (retain != null) retain += after.length!;
    }
    if (retain == 0) {
      return null;
    }

    delta..retain(beg)..retain(retain!, attribute.toJson());
    return delta;
  }
}

class ResolveInlineFormatRule extends FormatRule {
  const ResolveInlineFormatRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    if (attribute!.scope != AttributeScope.INLINE) {
      return null;
    }

    final delta = Delta()..retain(index);
    final it = DeltaIterator(document)..skip(index);

    Operation op;
    for (var cur = 0; cur < length! && it.hasNext; cur += op.length!) {
      op = it.next(length - cur);
      final text = op.data is String ? (op.data as String?)! : '';
      var lineBreak = text.indexOf('\n');
      if (lineBreak < 0) {
        delta.retain(op.length!, attribute.toJson());
        continue;
      }
      var pos = 0;
      while (lineBreak >= 0) {
        delta..retain(lineBreak - pos, attribute.toJson())..retain(1);
        pos = lineBreak + 1;
        lineBreak = text.indexOf('\n', pos);
      }
      if (pos < op.length!) {
        delta.retain(op.length! - pos, attribute.toJson());
      }
    }

    return delta;
  }
}

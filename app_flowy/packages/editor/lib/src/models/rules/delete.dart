import '../documents/attribute.dart';
import '../quill_delta.dart';
import 'rule.dart';

abstract class DeleteRule extends Rule {
  const DeleteRule();

  @override
  RuleType get type => RuleType.DELETE;

  @override
  void validateArgs(int? len, Object? data, Attribute? attribute) {
    assert(len != null);
    assert(data == null);
    assert(attribute == null);
  }
}

class CatchAllDeleteRule extends DeleteRule {
  const CatchAllDeleteRule();

  @override
  Delta applyRule(Delta document, int index,
      {int? len, Object? data, Attribute? attribute}) {
    return Delta()
      ..retain(index)
      ..delete(len!);
  }
}

class PreserveLineStyleOnMergeRule extends DeleteRule {
  const PreserveLineStyleOnMergeRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? len, Object? data, Attribute? attribute}) {
    final itr = DeltaIterator(document)..skip(index);
    var op = itr.next(1);
    if (op.data != '\n') {
      return null;
    }

    final isNotPlain = op.isNotPlain;
    final attrs = op.attributes;

    itr.skip(len! - 1);
    final delta = Delta()
      ..retain(index)
      ..delete(len);

    while (itr.hasNext) {
      op = itr.next();
      final text = op.data is String ? (op.data as String?)! : '';
      final lineBreak = text.indexOf('\n');
      if (lineBreak == -1) {
        delta.retain(op.length!);
        continue;
      }

      var attributes = op.attributes == null
          ? null
          : op.attributes!.map<String, dynamic>(
              (key, dynamic value) => MapEntry<String, dynamic>(key, null));

      if (isNotPlain) {
        attributes ??= <String, dynamic>{};
        attributes.addAll(attrs!);
      }
      delta
        ..retain(lineBreak)
        ..retain(1, attributes);
      break;
    }
    return delta;
  }
}

class EnsureEmbedLineRule extends DeleteRule {
  const EnsureEmbedLineRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? len, Object? data, Attribute? attribute}) {
    final itr = DeltaIterator(document);

    var op = itr.skip(index);
    int? indexDelta = 0, lengthDelta = 0, remain = len;
    var embedFound = op != null && op.data is! String;
    final hasLineBreakBefore =
        !embedFound && (op == null || (op.data as String).endsWith('\n'));
    if (embedFound) {
      var candidate = itr.next(1);
      if (remain != null) {
        remain--;
        if (candidate.data == '\n') {
          indexDelta++;
          lengthDelta--;

          candidate = itr.next(1);
          remain--;
          if (candidate.data == '\n') {
            lengthDelta++;
          }
        }
      }
    }

    op = itr.skip(remain!);
    if (op != null &&
        (op.data is String ? op.data as String? : '')!.endsWith('\n')) {
      final candidate = itr.next(1);
      if (candidate.data is! String && !hasLineBreakBefore) {
        embedFound = true;
        lengthDelta--;
      }
    }

    if (!embedFound) {
      return null;
    }

    return Delta()
      ..retain(index + indexDelta)
      ..delete(len! + lengthDelta);
  }
}

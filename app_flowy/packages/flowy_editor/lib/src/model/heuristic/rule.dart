import '../document/attribute.dart';
import '../document/document.dart';
import '../quill_delta.dart';
import 'insert.dart';
import 'delete.dart';
import 'format.dart';

enum RuleType {
  INSERT,
  DELETE,
  FORMAT,
}

abstract class Rule {
  const Rule();

  RuleType get type;

  Delta? apply(Delta document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    validateArgs(length, data, attribute);
    return applyRule(
      document,
      index,
      length: length,
      data: data,
      attribute: attribute,
    );
  }

  Delta? applyRule(Delta document, int index,
      {int? length, Object? data, Attribute? attribute});

  void validateArgs(int? length, Object? data, Attribute? attribute);
}

class Rules {
  Rules(this._rules);

  final List<Rule> _rules;

  static final Rules _instance = Rules([
    const FormatLinkAtCaretPositionRule(),
    const ResolveLineFormatRule(),
    const ResolveInlineFormatRule(),
    // const InsertEmbedsRule(),
    // const ForceNewlineForInsertsAroundEmbedRule(),
    const AutoExitBlockRule(),
    const PreserveBlockStyleOnInsertRule(),
    const PreserveLineStyleOnSplitRule(),
    const ResetLineFormatOnNewLineRule(),
    const AutoFormatLinksRule(),
    const PreserveInlineStylesRule(),
    const CatchAllInsertRule(),
    // const EnsureEmbedLineRule(),
    const PreserveLineStyleOnMergeRule(),
    const CatchAllDeleteRule(),
  ]);

  static Rules getInstance() => _instance;

  Delta apply(RuleType ruleType, Document document, int index,
      {int? length, Object? data, Attribute? attribute}) {
    final delta = document.toDelta();
    for (final rule in _rules) {
      if (rule.type != ruleType) {
        continue;
      }
      try {
        final result = rule.apply(delta, index,
            length: length, data: data, attribute: attribute);
        if (result != null) {
          print('apply rule: $rule, result: $result');
          return result..trim();
        }
      } catch (e) {
        rethrow;
      }
    }
    throw 'Apply rules failed';
  }
}

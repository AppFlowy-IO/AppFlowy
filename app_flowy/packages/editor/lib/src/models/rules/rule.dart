import '../documents/attribute.dart';
import '../documents/document.dart';
import '../quill_delta.dart';
import 'delete.dart';
import 'format.dart';
import 'insert.dart';

enum RuleType { INSERT, DELETE, FORMAT }

abstract class Rule {
  const Rule();

  Delta? apply(Delta document, int index,
      {int? len, Object? data, Attribute? attribute}) {
    validateArgs(len, data, attribute);
    return applyRule(document, index,
        len: len, data: data, attribute: attribute);
  }

  void validateArgs(int? len, Object? data, Attribute? attribute);

  Delta? applyRule(Delta document, int index,
      {int? len, Object? data, Attribute? attribute});

  RuleType get type;
}

class Rules {
  Rules(this._rules);

  List<Rule> _customRules = [];

  final List<Rule> _rules;
  static final Rules _instance = Rules([
    const FormatLinkAtCaretPositionRule(),
    const ResolveLineFormatRule(),
    const ResolveInlineFormatRule(),
    const InsertEmbedsRule(),
    const AutoExitBlockRule(),
    const PreserveBlockStyleOnInsertRule(),
    const PreserveLineStyleOnSplitRule(),
    const ResetLineFormatOnNewLineRule(),
    const AutoFormatLinksRule(),
    const PreserveInlineStylesRule(),
    const CatchAllInsertRule(),
    const EnsureEmbedLineRule(),
    const PreserveLineStyleOnMergeRule(),
    const CatchAllDeleteRule(),
  ]);

  static Rules getInstance() => _instance;

  void setCustomRules(List<Rule> customRules) {
    _customRules = customRules;
  }

  Delta apply(RuleType ruleType, Document document, int index,
      {int? len, Object? data, Attribute? attribute}) {
    final delta = document.toDelta();
    for (final rule in _customRules + _rules) {
      if (rule.type != ruleType) {
        continue;
      }
      try {
        final result = rule.apply(delta, index,
            len: len, data: data, attribute: attribute);
        if (result != null) {
          return result..trim();
        }
      } catch (e) {
        rethrow;
      }
    }
    throw 'Apply rules failed';
  }
}

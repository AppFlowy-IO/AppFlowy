import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/markdown_latex_utils.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;

/// Markdown parser that detects LaTeX/math blocks and converts them to
/// AppFlowy `mathEquationNode`.
///
/// This parser runs after markdown has processed the content, meaning
/// newlines in the original LaTeX may have been collapsed into spaces.
/// The shared utility functions handle fixing line breaks in this scenario.
class MarkdownMathEquationParser extends CustomMarkdownParser {
  const MarkdownMathEquationParser();

  /// Transform a Markdown AST node into a list of AppFlowy editor nodes.
  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    if (element is! md.Element) {
      return <Node>[];
    }

    if (element.tag != 'p') {
      return <Node>[];
    }

    final String textContent = element.textContent;

    // $$ ... $$
    Match? match = dollarDisplayRegex.firstMatch(textContent);

    if (match != null) {
      String formula = match.group(1)?.trim() ?? '';
      formula = fixLatexLineBreaksCollapsed(formula);
      formula = fixLatexSpacing(formula);
      return <Node>[mathEquationNode(formula: formula)];
    }

    // \[ ... \]
    match = escapedBracketRegex.firstMatch(textContent);

    if (match != null) {
      String formula = match.group(1)?.trim() ?? '';
      formula = fixLatexLineBreaksCollapsed(formula);
      formula = fixLatexSpacing(formula);
      return <Node>[mathEquationNode(formula: formula)];
    }

    // [ ... ]  (custom bracket that may contain LaTeX)
    match = bracketDisplayRegex.firstMatch(textContent);

    if (match != null) {
      String content = match.group(1)?.trim() ?? '';
      if (looksLikeLaTeX(content)) {
        content = fixLatexLineBreaksCollapsed(content);
        content = fixLatexSpacing(content);
        return <Node>[mathEquationNode(formula: content)];
      }
    }

    // \( ... \)
    match = parenDisplayRegex.firstMatch(textContent);

    if (match != null) {
      String formula = match.group(1)?.trim() ?? '';
      formula = fixLatexLineBreaksCollapsed(formula);
      formula = fixLatexSpacing(formula);
      return <Node>[mathEquationNode(formula: formula)];
    }

    return <Node>[];
  }
}

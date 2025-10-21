import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;

/// Markdown parser that detects LaTeX/math blocks and converts them to
/// AppFlowy `mathEquationNode`.
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
    final RegExp dollarDisplayRegex =
        RegExp(r'^\s*\$\$(.+?)\$\$\s*$', dotAll: true);
    Match? match = dollarDisplayRegex.firstMatch(textContent);

    if (match != null) {
      String formula = match.group(1)?.trim() ?? '';
      formula = _fixLatexLineBreaks(formula);
      formula = _fixLatexSpacing(formula);
      return <Node>[mathEquationNode(formula: formula)];
    }

    // \[ ... \]
    final RegExp bracketDisplayRegex =
        RegExp(r'^\s*\\\[(.+?)\\\]\s*$', dotAll: true);
    match = bracketDisplayRegex.firstMatch(textContent);

    if (match != null) {
      String formula = match.group(1)?.trim() ?? '';
      formula = _fixLatexLineBreaks(formula);
      formula = _fixLatexSpacing(formula);
      return <Node>[mathEquationNode(formula: formula)];
    }

    // [ ... ]  (custom bracket that may contain LaTeX)
    final RegExp plainBracketRegex = RegExp(r'^\s*\[(.+?)\]\s*$', dotAll: true);
    match = plainBracketRegex.firstMatch(textContent);

    if (match != null) {
      String content = match.group(1)?.trim() ?? '';
      if (_looksLikeLaTeX(content)) {
        content = _fixLatexLineBreaks(content);
        content = _fixLatexSpacing(content);
        return <Node>[mathEquationNode(formula: content)];
      }
    }

    // \( ... \)
    final RegExp parenInlineRegex =
        RegExp(r'^\s*\\\((.+?)\\\)\s*$', dotAll: true);
    match = parenInlineRegex.firstMatch(textContent);

    if (match != null) {
      String formula = match.group(1)?.trim() ?? '';
      formula = _fixLatexLineBreaks(formula);
      formula = _fixLatexSpacing(formula);
      return <Node>[mathEquationNode(formula: formula)];
    }

    return <Node>[];
  }

  /// Heuristic check whether a string looks like LaTeX.
  bool _looksLikeLaTeX(String content) =>
      content.contains('\\') ||
      content.contains(RegExp(r'[_^]\{')) ||
      content.contains(r'\begin') ||
      content.contains(r'\int') ||
      content.contains(r'\sum') ||
      content.contains(r'\frac') ||
      content.contains(r'\lim') ||
      content.contains(r'\text') ||
      content.contains(RegExp(r'[a-zA-Z0-9]\s*[+\-*/=]\s*[a-zA-Z0-9]')) ||
      content.contains(RegExp(r'\^[0-9]'));

  /// Ensure common spacing in LaTeX (e.g. `\, dx`).
  String _fixLatexSpacing(String latex) {
    String result = latex;
    result = result.replaceAll(', dx', r'\, dx');
    result = result.replaceAll(', dy', r'\, dy');
    result = result.replaceAll(', dz', r'\, dz');
    result = result.replaceAll(', dt', r'\, dt');
    result = result.replaceAll(', dV', r'\, dV');
    result = result.replaceAll(', dA', r'\, dA');
    result = result.replaceAll(', ds', r'\, ds');
    result = result.replaceAll(', du', r'\, du');
    result = result.replaceAll(', dv', r'\, dv');
    result = result.replaceAll(', dw', r'\, dw');
    return result;
  }

  /// Fix line breaks inside LaTeX environments so rows end with `\\\\` where needed.
  String _fixLatexLineBreaks(String latex) {
    final bool hasEnvironment = latex.contains(r'\begin{cases}') ||
        latex.contains(r'\begin{aligned}') ||
        latex.contains(r'\begin{array}');

    if (!hasEnvironment) {
      return latex;
    }

    // Avoid sequences like " \-" being treated poorly.
    String result = latex.replaceAll(RegExp(r'(?<!\\)\\-'), r'\\ -');

    // Replace single backslash followed by spaces and a letter/digit with a double
    // backslash + space + char, but keep existing escaped sequences intact.
    result = result.replaceAllMapped(
      RegExp(r'\\\s+([a-zA-Z0-9-])'),
      (Match m) {
        final String char = m.group(1)!;
        final int beforeIndex = m.start;

        if (beforeIndex >= 1 && result[beforeIndex - 1] == '\\') {
          return m.group(0)!;
        }
        return '\\\\ $char';
      },
    );

    // Add explicit row line-breaks inside array/aligned/cases when appropriate.
    result = result.replaceAllMapped(
      RegExp(r'([}\w\d])\s+([a-zA-Z-])'),
      (Match m) {
        final String before = m.group(1)!;
        final String after = m.group(2)!;
        final int index = m.start;

        if (index >= 2) {
          final String twoCharsBefore = result.substring(index - 2, index);
          if (twoCharsBefore == r'\\') {
            return m.group(0)!;
          }
        }

        final String beforeContext = result.substring(0, m.start);

        if (beforeContext.endsWith(r'\begin{cases}') ||
            beforeContext.endsWith(r'\begin{aligned}') ||
            beforeContext.endsWith(r'\begin{array}')) {
          return m.group(0)!;
        }

        final int openTextCount = beforeContext.split(r'\text{').length - 1;
        final int closeBraceCount = beforeContext.split('}').length - 1;
        if (openTextCount > closeBraceCount) {
          return m.group(0)!;
        }

        if (before == '}') {
          final int textPattern = beforeContext.lastIndexOf(r'\text{');
          if (textPattern >= 0) {
            final String afterText = beforeContext.substring(textPattern);
            final int openCount = afterText.split('{').length - 1;
            final int closeCount = afterText.split('}').length - 1;
            if (openCount == closeCount + 1) {
              return m.group(0)!;
            }
          }
        }

        final int lastBackslash = beforeContext.lastIndexOf('\\');
        if (lastBackslash >= 0) {
          final String sinceLast = beforeContext.substring(lastBackslash + 1);
          if (sinceLast.isNotEmpty && !sinceLast.contains(' ') && !sinceLast.contains('&')) {
            return m.group(0)!;
          }
        }

        final int lastAmpersand = beforeContext.lastIndexOf('&');
        if (lastAmpersand >= 0) {
          final String sinceAmpersand = beforeContext.substring(lastAmpersand + 1);
          if (!sinceAmpersand.contains(r'\\')) {
            return '$before \\\\ $after';
          }
        }

        return m.group(0)!;
      },
    );

    return result;
  }
}

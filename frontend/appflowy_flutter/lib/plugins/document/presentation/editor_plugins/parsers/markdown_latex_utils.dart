/// Shared utilities for LaTeX equation processing.
///
/// This file contains common LaTeX parsing and fixing logic used across
/// different markdown processors to ensure consistent behavior when
/// handling pasted mathematical equations.

// Regular expression patterns used for LaTeX detection and parsing
// Extracted as constants for better performance and readability

/// Matches LaTeX blocks in square brackets with newlines: [<content>]
final RegExp latexBlockRegex = RegExp(
  r'^\[\s*\n((?:.*\n)*?.*?)\s*\]',
  multiLine: true,
);

/// Matches display math blocks: $$<content>$$
final RegExp dollarDisplayRegex = RegExp(r'^\s*\$\$(.+?)\$\$\s*$', dotAll: true);

/// Matches inline math: $<content>$
final RegExp dollarInlineRegex = RegExp(r'^\s*\$(.+?)\$\s*$', dotAll: true);

/// Matches bracket blocks: [<content>]
final RegExp bracketDisplayRegex = RegExp(r'^\s*\[(.+?)\]\s*$', dotAll: true);

/// Matches escaped bracket blocks: \\[<content>\\]
final RegExp escapedBracketRegex = RegExp(r'^\s*\\\[(.+?)\\\]\s*$', dotAll: true);

/// Matches paren blocks: \\(<content>\\)
final RegExp parenDisplayRegex = RegExp(r'^\s*\\\((.+?)\\\)\s*$', dotAll: true);

/// Detects invalid `\-` command (backslash followed by minus)
final RegExp invalidBackslashMinusRegex = RegExp(r'(?<!\\)\\-');

/// Detects single backslash followed by whitespace and alphanumeric
final RegExp singleBackslashSpaceRegex = RegExp(r'\\\s+([a-zA-Z0-9-])');

/// Detects potential row breaks: closing brace/word/digit followed by space and letter/dash
final RegExp potentialRowBreakRegex = RegExp(r'([}\w\d])\s+([a-zA-Z-])');

/// Checks if a string contains LaTeX syntax.
///
/// Returns true if the content includes common LaTeX commands, environments,
/// or mathematical notation patterns.
bool containsLaTeX(String content) {
  return content.contains(r'\int') ||
      content.contains(r'\sum') ||
      content.contains(r'\frac') ||
      content.contains(r'\lim') ||
      content.contains(r'\text') ||
      content.contains(r'\begin') ||
      content.contains(r'\iint') ||
      content.contains(r'\iiint') ||
      content.contains(RegExp(r'\\[a-zA-Z]+')) ||
      content.contains(RegExp(r'[_^]\{')) ||
      content.contains(RegExp(r'[a-zA-Z0-9]\s*[+\-*/=]\s*[a-zA-Z0-9]')) ||
      content.contains(RegExp(r'\^[0-9]'));
}

/// Checks if a string looks like LaTeX (alternative implementation).
///
/// This is a lighter-weight check used by the markdown parser.
bool looksLikeLaTeX(String content) {
  return content.contains(r'\') ||
      content.contains(RegExp(r'[_^]\{')) ||
      content.contains('\\begin') ||
      content.contains('\\int') ||
      content.contains('\\sum') ||
      content.contains('\\frac') ||
      content.contains('\\lim') ||
      content.contains('\\text') ||
      content.contains(RegExp(r'[a-zA-Z0-9]\s*[+\-*/=]\s*[a-zA-Z0-9]')) ||
      content.contains(RegExp(r'\^[0-9]'));
}

/// Fixes LaTeX spacing by converting comma-space patterns to thin spaces.
///
/// In proper LaTeX integral notation, differential variables should be
/// preceded by a thin space (`\,`) rather than a comma. This function
/// converts patterns like `, dx` to `\, dx` for common differential variables.
///
/// Example: `\int x^2, dx` → `\int x^2\, dx`
String fixLatexSpacing(String latex) {
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

/// Fixes LaTeX line breaks for multi-line environments when newlines are intact.
///
/// This function processes LaTeX content line-by-line, converting single
/// backslashes at the end of lines to double backslashes (`\\`) which are
/// required for row separators in environments like `cases`, `aligned`, and `array`.
///
/// This version is used when the original newlines are preserved (e.g., in
/// preprocessing of `[...]` blocks before markdown parsing).
///
/// Example:
/// ```
/// \begin{cases}
/// x^2 & \text{if } x \geq 0 \
/// -x & \text{if } x < 0
/// \end{cases}
/// ```
/// becomes:
/// ```
/// \begin{cases}
/// x^2 & \text{if } x \geq 0 \\
/// -x & \text{if } x < 0
/// \end{cases}
/// ```
String fixLatexLineBreaksWithNewlines(String latex) {
  if (!latex.contains(r'\begin{cases}') &&
      !latex.contains(r'\begin{aligned}') &&
      !latex.contains(r'\begin{array}')) {
    return latex;
  }

  final lines = latex.split('\n');
  final result = <String>[];
  bool inEnvironment = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Track when we enter multi-line environments
    if (line.contains(r'\begin{cases}') ||
        line.contains(r'\begin{aligned}') ||
        line.contains(r'\begin{array}')) {
      inEnvironment = true;
      result.add(line);
      continue;
    }

    // Track when we exit multi-line environments
    if (line.contains(r'\end{cases}') ||
        line.contains(r'\end{aligned}') ||
        line.contains(r'\end{array}')) {
      inEnvironment = false;
      result.add(line);
      continue;
    }

    // Only process lines inside multi-line environments
    if (!inEnvironment) {
      result.add(line);
      continue;
    }

    final trimmed = line.trimRight();

    // Empty lines don't need processing
    if (trimmed.isEmpty) {
      result.add(line);
      continue;
    }

    // Already has double backslash - leave it alone
    if (trimmed.endsWith(r'\\')) {
      result.add(line);
      continue;
    }

    // Convert single backslash at end of line to double backslash
    // This handles the common case of pasted LaTeX from ChatGPT which
    // uses single backslashes for line breaks
    if (trimmed.isNotEmpty && trimmed[trimmed.length - 1] == '\\') {
      if (trimmed.length < 2 || trimmed[trimmed.length - 2] != '\\') {
        final withoutSlash = trimmed.substring(0, trimmed.length - 1);
        final trailingSpaces = line.substring(trimmed.length);
        result.add('$withoutSlash\\\\$trailingSpaces');
        continue;
      }
    }

    // Check if this is the last line before the environment ends
    // If so, don't add a row separator
    if (i + 1 < lines.length) {
      final nextLine = lines[i + 1].trim();
      if (nextLine.startsWith(r'\end{cases}') ||
          nextLine.startsWith(r'\end{aligned}') ||
          nextLine.startsWith(r'\end{array}')) {
        result.add(line);
        continue;
      }
    }

    // Add double backslash at end of line for row separator
    result.add('$trimmed \\\\');
  }

  return result.join('\n');
}

/// Fixes LaTeX line breaks for multi-line environments when newlines are collapsed.
///
/// This function handles LaTeX content where newlines have been collapsed into
/// spaces by markdown processing. It intelligently detects where row breaks
/// should occur and adds `\\` separators while avoiding breaking valid LaTeX
/// constructs like `\text{...}` blocks.
///
/// This version is used after markdown has processed the content and collapsed
/// the newlines (e.g., in the markdown_math_equation_parser).
///
/// Key behaviors:
/// - Fixes invalid `\-` sequences (should be `\\ -`)
/// - Detects transitions between equation rows
/// - Preserves `\text{...}` blocks without adding breaks mid-condition
/// - Adds `\\` only at actual row boundaries
///
/// Example (collapsed):
/// ```
/// f(x) = \begin{cases} x^2 & \text{if } x \geq 0 -x & \text{if } x < 0 \end{cases}
/// ```
/// becomes:
/// ```
/// f(x) = \begin{cases} x^2 & \text{if } x \geq 0 \\ -x & \text{if } x < 0 \end{cases}
/// ```
String fixLatexLineBreaksCollapsed(String latex) {
  if (!latex.contains(r'\begin{cases}') &&
      !latex.contains(r'\begin{aligned}') &&
      !latex.contains(r'\begin{array}')) {
    return latex;
  }

  String result = latex;

  // Fix invalid `\-` command that can occur when markdown collapses
  // a backslash-newline-minus pattern into `\-`
  // Example: "\ \n -x" becomes "\-x" which is invalid LaTeX
  // We convert it to "\\ -x" (proper row break followed by negative number)
  result = result.replaceAll(invalidBackslashMinusRegex, r'\\ -');

  // Replace single backslash followed by spaces and a letter/digit with double backslash
  // This handles cases where markdown collapsed "\ \n x" into "\ x"
  // Example: "\ x" should become "\\ x"
  result = result.replaceAllMapped(
    singleBackslashSpaceRegex,
    (match) {
      final char = match.group(1)!;
      final beforeIndex = match.start;
      // Avoid replacing if already preceded by a backslash (would make \\\)
      if (beforeIndex >= 1 && result[beforeIndex - 1] == '\\') {
        return match.group(0)!;
      }
      return '\\\\ $char';
    },
  );

  // Detect and add `\\` before potential new rows
  // This is the most complex part: we need to determine when a space
  // between elements actually represents a new row in the original LaTeX
  //
  // Key insight: In piecewise functions like:
  //   x^2 & \text{if } x >= 0
  //   -x & \text{if } x < 0
  // When collapsed, this becomes:
  //   x^2 & \text{if } x >= 0 -x & \text{if } x < 0
  //                           ^--- this space represents a new row
  //
  // We detect this by looking for patterns like "} -" or "0 -" where
  // the space is likely a collapsed newline, BUT we must avoid breaking
  // inside \text{...} blocks.
  result = result.replaceAllMapped(
    potentialRowBreakRegex,
    (match) {
      final before = match.group(1)!;
      final after = match.group(2)!;
      final index = match.start;

      // Don't add \\ if already preceded by \\
      if (index >= 2) {
        final twoCharsBefore = result.substring(index - 2, index);
        if (twoCharsBefore == r'\\') {
          return match.group(0)!;
        }
      }

      final beforeContext = result.substring(0, match.start);

      // Don't add \\ right after environment begin
      if (beforeContext.endsWith(r'\begin{cases}') ||
          beforeContext.endsWith(r'\begin{aligned}') ||
          beforeContext.endsWith(r'\begin{array}')) {
        return match.group(0)!;
      }

      // Don't add \\ if we're inside an unclosed \text{...} block
      final openTextCount = beforeContext.split(r'\text{').length - 1;
      final closeBraceCount = beforeContext.split('}').length - 1;
      if (openTextCount > closeBraceCount) {
        return match.group(0)!;
      }

      // CRITICAL: Skip if the closing brace is from \text{...}
      // This prevents breaking conditions like "& \text{if } x >= 0"
      // into "& \text{if } \\ x >= 0" which would be wrong
      if (before == '}') {
        final textPattern = beforeContext.lastIndexOf(r'\text{');
        if (textPattern >= 0) {
          final afterText = beforeContext.substring(textPattern);
          final openCount = afterText.split('{').length - 1;
          final closeCount = afterText.split('}').length - 1;
          // If braces just balanced, this } closes a \text{}, skip it
          if (openCount == closeCount + 1) {
            return match.group(0)!;
          }
        }
      }

      // Don't add \\ if we're right after a backslash command
      final lastBackslash = beforeContext.lastIndexOf('\\');
      if (lastBackslash >= 0) {
        final sinceLast = beforeContext.substring(lastBackslash + 1);
        if (sinceLast.isNotEmpty &&
            !sinceLast.contains(' ') &&
            !sinceLast.contains('&')) {
          return match.group(0)!;
        }
      }

      // If we found an ampersand (&) but no row separator since then,
      // this is likely a new row
      final lastAmpersand = beforeContext.lastIndexOf('&');
      if (lastAmpersand >= 0) {
        final sinceAmpersand = beforeContext.substring(lastAmpersand + 1);
        if (!sinceAmpersand.contains(r'\\')) {
          return '$before \\\\ $after';
        }
      }

      return match.group(0)!;
    },
  );

  return result;
}

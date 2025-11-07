import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_plain_text.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:html2md/html2md.dart' as html2md;

extension PasteFromHtml on EditorState {
  Future<bool> pasteHtml(String html) async {
    final nodes = convertHtmlToNodes(html);
    // if there's no nodes being converted successfully, return false
    if (nodes.isEmpty) {
      return false;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
      checkToShowPasteAsMenu(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
    return true;
  }

  /// Convert HTML to document nodes using the appropriate parser.
  ///
  /// This method implements a decision tree to choose between two parsing approaches:
  /// 1. HTML-to-markdown-to-nodes: Better for structured content (lists, math, tables)
  /// 2. HTML-to-nodes directly: Faster for simple formatted text
  ///
  /// **Decision Flow:**
  /// ```
  /// ┌─ Detect content type (Google Docs, Apple Notes, lists, math)
  /// │
  /// ├─ If (Google Docs OR lists OR math) AND NOT Apple Notes:
  /// │  └─> Use html2md → customMarkdownToDocument
  /// │      (Preserves LaTeX equations, list structure, nested formatting)
  /// │
  /// └─ Else:
  ///    ├─> Try htmlToDocument first (faster for simple content)
  ///    ├─> Clean up empty nodes
  ///    ├─> Convert legacy tables to simple tables
  ///    └─> If result is empty OR contains tables:
  ///        └─> Fallback to html2md → customMarkdownToDocument
  /// ```
  ///
  /// **Why two paths?**
  /// - Markdown path: Handles LaTeX preprocessing (see markdown_to_document.dart)
  ///   which fixes line breaks in piecewise functions and converts spacing
  /// - Direct HTML path: Simpler and faster for plain formatted text
  /// - Apple Notes exception: Known to work better with direct HTML parsing
  ///
  /// For Google Docs tables, it will fallback to the markdown parser.
  List<Node> convertHtmlToNodes(String html) {
    // ========== Step 1: Detect content source and type ==========
    const googleDocsFlag = 'docs-internal-guid-';
    final isPasteFromGoogleDocs = html.contains(googleDocsFlag);
    final isPasteFromAppleNotes = appleNotesRegex.hasMatch(html);

    // Detect if HTML contains list structures
    // Lists need markdown parser to preserve nesting and ordering
    final containsListStructures = html.contains('<ul>') ||
                                   html.contains('<ol>') ||
                                   html.contains('<li>');

    // Detect LaTeX/math content patterns
    // Math equations need markdown parser for LaTeX preprocessing
    // (fixes line breaks, spacing, etc. - see markdown_latex_utils.dart)
    final containsMathContent = html.contains(r'\(') ||
                               html.contains(r'\[') ||
        html.contains(r'$$') ||
                               html.contains(r'\begin') ||
                               html.contains('math-inline') ||
                               html.contains('math-display');

    List<Node> nodes = [];

    // ========== Step 2: Choose parsing strategy ==========
    // Use markdown converter when:
    // - Content is from Google Docs (better structure preservation)
    // - Content has lists (preserves nesting and ordering)
    // - Content has math (enables LaTeX preprocessing)
    // UNLESS it's from Apple Notes (which works better with direct HTML parsing)
    final shouldUseMarkdownConverter = isPasteFromGoogleDocs ||
                                       containsListStructures ||
                                       containsMathContent;

    if (shouldUseMarkdownConverter && !isPasteFromAppleNotes) {
      // ========== Path A: HTML → Markdown → Document ==========
      // Convert HTML to markdown, then parse to document nodes
      // This path enables:
      // - LaTeX preprocessing (line breaks, spacing fixes)
      // - Better list structure preservation
      // - Proper handling of nested formatting
      final markdown = html2md.convert(html);
      nodes = customMarkdownToDocument(markdown, tableWidth: 200)
          .root
          .children
          .toList();
    } else {
      // ========== Path B: HTML → Document (with fallback) ==========
      // Try direct HTML to document conversion first (faster for simple content)
      nodes = htmlToDocument(html).root.children.toList();

      // Post-process: Remove leading/trailing empty nodes
      // (HTML parser sometimes creates empty paragraphs from formatting tags)
      while (nodes.isNotEmpty && nodes.first.delta?.isEmpty == true) {
        nodes.removeAt(0);
      }
      while (nodes.isNotEmpty && nodes.last.delta?.isEmpty == true) {
        nodes.removeLast();
      }

      // Post-process: Convert legacy table format to new simple table format
      // (Ensures compatibility with newer table implementation)
      for (int i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        if (node.type == TableBlockKeys.type) {
          nodes[i] = _convertTableToSimpleTable(node);
        }
      }

      // Fallback check: If HTML parsing failed or produced tables,
      // use markdown parser instead (better table handling)
      final containsTable = nodes.any(
        (node) =>
            [TableBlockKeys.type, SimpleTableBlockKeys.type].contains(node.type),
      );
      if (nodes.isEmpty || containsTable) {
        // Fallback to markdown parser for better structure handling
        final markdown = html2md.convert(html);
        nodes = customMarkdownToDocument(markdown, tableWidth: 200)
            .root
            .children
            .toList();
      }
    }

    // 4. check if the first node and the last node is bold, because google docs will wrap the table with bold tags
    if (isPasteFromGoogleDocs) {
      if (nodes.isNotEmpty && nodes.first.delta?.toPlainText() == '**') {
        nodes.removeAt(0);
      }
      if (nodes.isNotEmpty && nodes.last.delta?.toPlainText() == '**') {
        nodes.removeLast();
      }
    }

    return nodes;
  }

  // convert the legacy table node to the new simple table node
  // from type 'table' to type 'simple_table'
  Node _convertTableToSimpleTable(Node node) {
    if (node.type != TableBlockKeys.type) {
      return node;
    }

    // the table node should contains colsLen and rowsLen
    final colsLen = node.attributes[TableBlockKeys.colsLen];
    final rowsLen = node.attributes[TableBlockKeys.rowsLen];
    if (colsLen == null || rowsLen == null) {
      return node;
    }

    final rows = <List<Node>>[];
    final children = node.children;
    for (var i = 0; i < rowsLen; i++) {
      final row = <Node>[];
      for (var j = 0; j < colsLen; j++) {
        final cell = children
            .where(
              (n) =>
                  n.attributes[TableCellBlockKeys.rowPosition] == i &&
                  n.attributes[TableCellBlockKeys.colPosition] == j,
            )
            .firstOrNull;
        row.add(
          simpleTableCellBlockNode(
            children: cell?.children.map((e) => e.deepCopy()).toList() ??
                [paragraphNode()],
          ),
        );
      }
      rows.add(row);
    }

    return simpleTableBlockNode(
      children: rows.map((e) => simpleTableRowBlockNode(children: e)).toList(),
    );
  }
}
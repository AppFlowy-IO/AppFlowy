import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// Parser for converting SimpleTable nodes to markdown format
class SimpleTableNodeParser extends NodeParser {
  const SimpleTableNodeParser();

  @override
  String get id => SimpleTableBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    try {
      final tableData = _extractTableData(node, encoder);
      if (tableData.isEmpty) {
        return '';
      }
      return _buildMarkdownTable(tableData);
    } catch (e) {
      return '';
    }
  }

  /// Extracts table data from the node structure into a 2D list of strings
  /// Each inner list represents a row, and each string represents a cell's content
  List<List<String>> _extractTableData(
    Node node,
    DocumentMarkdownEncoder? encoder,
  ) {
    final tableData = <List<String>>[];
    final rows = node.children;

    for (final row in rows) {
      final rowData = _extractRowData(row, encoder);
      tableData.add(rowData);
    }

    return tableData;
  }

  /// Extracts data from a single table row
  List<String> _extractRowData(Node row, DocumentMarkdownEncoder? encoder) {
    final rowData = <String>[];
    final cells = row.children;

    for (final cell in cells) {
      final content = _extractCellContent(cell, encoder);
      rowData.add(content);
    }

    return rowData;
  }

  /// Extracts and formats content from a single table cell
  String _extractCellContent(Node cell, DocumentMarkdownEncoder? encoder) {
    final contentBuffer = StringBuffer();

    for (final child in cell.children) {
      final delta = child.delta;

      // if the node doesn't contain delta, fallback to the encoder
      final content = delta != null
          ? DeltaMarkdownEncoder().convert(delta)
          : encoder?.convertNodes([child]).trim() ?? '';

      // Escape pipe characters to prevent breaking markdown table structure
      contentBuffer.write(content.replaceAll('|', '\\|'));
    }

    return contentBuffer.toString();
  }

  /// Builds a markdown table string from the extracted table data
  /// First row is treated as header, followed by separator row and data rows
  String _buildMarkdownTable(List<List<String>> tableData) {
    final markdown = StringBuffer();
    final columnCount = tableData[0].length;

    // Add header row
    markdown.writeln('|${tableData[0].join('|')}|');

    // Add separator row
    markdown.writeln('|${List.filled(columnCount, '---').join('|')}|');

    // Add data rows (skip header row)
    for (int i = 1; i < tableData.length; i++) {
      markdown.writeln('|${tableData[i].join('|')}|');
    }

    return markdown.toString();
  }
}

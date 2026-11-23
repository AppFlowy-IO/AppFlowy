import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:universal_platform/universal_platform.dart';

class MarkdownSimpleTableParser extends CustomMarkdownParser {
  const MarkdownSimpleTableParser({
    this.tableWidth,
  });

  final double? tableWidth;

  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    if (element is! md.Element) {
      return [];
    }

    if (element.tag != 'table') {
      return [];
    }

    final ec = element.children;
    if (ec == null || ec.isEmpty) {
      return [];
    }

    final th = ec
        .whereType<md.Element>()
        .where((e) => e.tag == 'thead')
        .firstOrNull
        ?.children
        ?.whereType<md.Element>()
        .where((e) => e.tag == 'tr')
        .expand((e) => e.children?.whereType<md.Element>().toList() ?? [])
        .where((e) => e.tag == 'th')
        .toList();

    final tr = ec
        .whereType<md.Element>()
        .where((e) => e.tag == 'tbody')
        .firstOrNull
        ?.children
        ?.whereType<md.Element>()
        .where((e) => e.tag == 'tr');

    if (th == null || th.isEmpty) {
      return [];
    }

    final rows = <Node>[];

    // Add header cells

    rows.add(
      simpleTableRowBlockNode(
        children: th
            .map(
              (e) => simpleTableCellBlockNode(
                children: [
                  paragraphNode(
                    delta: DeltaMarkdownDecoder().convertNodes(e.children),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );

    // A single-row Markdown table has a header but no body.
    for (final row in tr ?? const <md.Element>[]) {
      final td = row.children
          ?.whereType<md.Element>()
          .where((e) => e.tag == 'td')
          .toList();

      if (td == null || td.isEmpty) {
        continue;
      }

      rows.add(
        simpleTableRowBlockNode(
          children: td
              .map(
                (e) => simpleTableCellBlockNode(
                  children: [
                    paragraphNode(
                      delta: DeltaMarkdownDecoder().convertNodes(e.children),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      );
    }

    return [
      simpleTableBlockNode(
        children: rows,
        enableHeaderRow: true,
        columnWidths: UniversalPlatform.isMobile || tableWidth == null
            ? null
            : {for (var i = 0; i < th.length; i++) i.toString(): tableWidth!},
      ),
    ];
  }
}

import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simple table markdown:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('convert simple table to markdown (1)', () async {
      final tableNode = createSimpleTableBlockNode(
        columnCount: 7,
        rowCount: 11,
        contentBuilder: (rowIndex, columnIndex) =>
            _sampleContents[rowIndex][columnIndex],
      );
      final markdown = const SimpleTableNodeParser().transform(
        tableNode,
        null,
      );
      expect(markdown,
          '''|Index|Customer Id|First Name|Last Name|Company|City|Country|
|---|---|---|---|---|---|---|
|1|DD37Cf93aecA6Dc|Sheryl|Baxter|Rasmussen Group|East Leonard|Chile|
|2|1Ef7b82A4CAAD10|Preston|Lozano|Vega-Gentry|East Jimmychester|Djibouti|
|3|6F94879bDAfE5a6|Roy|Berry|Murillo-Perry|Isabelborough|Antigua and Barbuda|
|4|5Cef8BFA16c5e3c|Linda|Olsen|Dominguez, Mcmillan and Donovan|Bensonview|Dominican Republic|
|5|053d585Ab6b3159|Joanna|Bender|Martin, Lang and Andrade|West Priscilla|Slovakia (Slovak Republic)|
|6|2d08FB17EE273F4|Aimee|Downs|Steele Group|Chavezborough|Bosnia and Herzegovina|
|7|EAd384DfDbBf77|Darren|Peck|Lester, Woodard and Mitchell|Lake Ana|Pitcairn Islands|
|8|0e04AFde9f225dE|Brett|Mullen|Sanford, Davenport and Giles|Kimport|Bulgaria|
|9|C2dE4dEEc489ae0|Sheryl|Meyers|Browning-Simon|Robersonstad|Cyprus|
|10|8C2811a503C7c5a|Michelle|Gallagher|Beck-Hendrix|Elaineberg|Timor-Leste|
''');
    });

    test('convert markdown to simple table (1)', () async {
      final document = customMarkdownToDocument(_sampleMarkdown1);
      expect(document, isNotNull);
      final tableNode = document.nodeAtPath([0])!;
      expect(tableNode, isNotNull);
      expect(tableNode.type, equals(SimpleTableBlockKeys.type));
      expect(tableNode.rowLength, equals(4));
      expect(tableNode.columnLength, equals(4));
    });
  });
}

const _sampleContents = <List<String>>[
  [
    "Index",
    "Customer Id",
    "First Name",
    "Last Name",
    "Company",
    "City",
    "Country",
  ],
  [
    "1",
    "DD37Cf93aecA6Dc",
    "Sheryl",
    "Baxter",
    "Rasmussen Group",
    "East Leonard",
    "Chile",
  ],
  [
    "2",
    "1Ef7b82A4CAAD10",
    "Preston",
    "Lozano",
    "Vega-Gentry",
    "East Jimmychester",
    "Djibouti",
  ],
  [
    "3",
    "6F94879bDAfE5a6",
    "Roy",
    "Berry",
    "Murillo-Perry",
    "Isabelborough",
    "Antigua and Barbuda",
  ],
  [
    "4",
    "5Cef8BFA16c5e3c",
    "Linda",
    "Olsen",
    "Dominguez, Mcmillan and Donovan",
    "Bensonview",
    "Dominican Republic",
  ],
  [
    "5",
    "053d585Ab6b3159",
    "Joanna",
    "Bender",
    "Martin, Lang and Andrade",
    "West Priscilla",
    "Slovakia (Slovak Republic)",
  ],
  [
    "6",
    "2d08FB17EE273F4",
    "Aimee",
    "Downs",
    "Steele Group",
    "Chavezborough",
    "Bosnia and Herzegovina",
  ],
  [
    "7",
    "EAd384DfDbBf77",
    "Darren",
    "Peck",
    "Lester, Woodard and Mitchell",
    "Lake Ana",
    "Pitcairn Islands",
  ],
  [
    "8",
    "0e04AFde9f225dE",
    "Brett",
    "Mullen",
    "Sanford, Davenport and Giles",
    "Kimport",
    "Bulgaria",
  ],
  [
    "9",
    "C2dE4dEEc489ae0",
    "Sheryl",
    "Meyers",
    "Browning-Simon",
    "Robersonstad",
    "Cyprus",
  ],
  [
    "10",
    "8C2811a503C7c5a",
    "Michelle",
    "Gallagher",
    "Beck-Hendrix",
    "Elaineberg",
    "Timor-Leste",
  ],
];

const _sampleMarkdown1 = '''|A|B|C||
|---|---|---|---|
|D|E|F||
|1|2|3||
|||||
''';

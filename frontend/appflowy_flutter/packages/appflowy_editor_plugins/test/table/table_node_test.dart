import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:appflowy_editor_plugins/src/table/table_const.dart';

void main() {
  group('table_node.dart', () {
    test('fromJson', () {
      final tableNode = TableNode.fromJson({
        'type': kTableType,
        'attributes': {
          'colsLen': 2,
          'rowsLen': 2,
          'config': {
            'colDefaultWidth': 60,
            'rowDefaultHeight': 50,
            'colMinimumWidth': 30,
          },
        },
        'children': [
          {
            'type': kTableCellType,
            'attributes': {
              'position': {'col': 0, 'row': 0},
              'width': 35,
            },
            'children': [
              {
                'type': 'text',
                "attributes": {"subtype": "heading", "heading": "h2"},
                "delta": [
                  {"insert": "a"}
                ]
              },
            ]
          },
          {
            'type': kTableCellType,
            'attributes': {
              'position': {'col': 0, 'row': 1},
            },
            'children': [
              {
                "type": "text",
                "delta": [
                  {
                    "insert": "b",
                    "attributes": {"bold": true}
                  }
                ]
              },
            ],
          },
          {
            'type': kTableCellType,
            'attributes': {
              'position': {'col': 1, 'row': 0},
            },
            'children': [
              {
                "type": "text",
                "delta": [
                  {
                    "insert": "c",
                    "attributes": {"italic": true}
                  }
                ]
              },
            ],
          },
          {
            'type': kTableCellType,
            'attributes': {
              'position': {'col': 1, 'row': 1},
            },
            'children': [
              {
                "type": "text",
                "delta": [
                  {"insert": "d"}
                ]
              }
            ]
          }
        ],
      });

      expect(tableNode.config.colMinimumWidth, 30);
      expect(tableNode.config.colDefaultWidth, 60);
      expect(tableNode.config.rowDefaultHeight, 50);

      expect(tableNode.getColWidth(0), 35);
      expect(tableNode.getColWidth(1), tableNode.config.colDefaultWidth);

      expect(tableNode.getRowHeight(0), tableNode.config.rowDefaultHeight);
      expect(tableNode.getRowHeight(1), tableNode.config.rowDefaultHeight);

      expect(
        tableNode.getCell(0, 0).children.first.toJson(),
        {
          'type': 'text',
          "attributes": {"subtype": "heading", "heading": "h2"},
          "delta": [
            {"insert": "a"}
          ]
        },
      );
      expect(
        tableNode.getCell(1, 0).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {
              "insert": "c",
              "attributes": {"italic": true}
            }
          ]
        },
      );

      expect(
        tableNode.getCell(1, 1).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {"insert": "d"}
          ]
        },
      );
    });

    test('fromJson - error when columns length mismatch', () {
      final jsonData = {
        'type': kTableType,
        'attributes': {
          'colsLen': 2,
          'rowsLen': 2,
          'config': {
            'colDefaultWidth': 60,
            'rowDefaultHeight': 50,
            'colMinimumWidth': 30,
          },
        },
        'children': [
          {
            'type': kTableCellType,
            'attributes': {
              'position': {'col': 0, 'row': 0},
              'width': 35,
            },
            'children': [
              {
                'type': 'text',
                "attributes": {"subtype": "heading", "heading": "h2"},
                "delta": [
                  {"insert": "a"}
                ]
              },
            ]
          },
          {
            'type': kTableCellType,
            'attributes': {
              'position': {'col': 1, 'row': 0},
            },
            'children': [
              {
                "type": "text",
                "delta": [
                  {
                    "insert": "c",
                    "attributes": {"italic": true}
                  }
                ]
              },
            ],
          },
          {
            'type': kTableCellType,
            'attributes': {
              'position': {'col': 1, 'row': 1},
            },
            'children': [
              {
                "type": "text",
                "delta": [
                  {"insert": "d"}
                ]
              }
            ]
          }
        ],
      };

      expect(() => TableNode.fromJson(jsonData), throwsAssertionError);
    });

    test('default constructor (from list of list of strings)', () {
      final tableNode = TableNode.fromList([
        ['1', '2'],
        ['3', '4']
      ]);
      const config = TableConfig();

      expect(tableNode.config.colMinimumWidth, config.colMinimumWidth);
      expect(tableNode.config.colDefaultWidth, config.colDefaultWidth);
      expect(tableNode.config.rowDefaultHeight, config.rowDefaultHeight);
      expect(tableNode.node.attributes['config']['colMinimumWidth'],
          config.colMinimumWidth);

      expect(tableNode.getColWidth(0), config.colDefaultWidth);
      expect(tableNode.getColWidth(1), config.colDefaultWidth);

      expect(tableNode.getRowHeight(0), config.rowDefaultHeight);
      expect(tableNode.getRowHeight(1), config.rowDefaultHeight);

      expect(
        tableNode.getCell(0, 0).children.first.toJson(),
        {
          'type': 'text',
          "delta": [
            {"insert": "1"}
          ]
        },
      );
      expect(
        tableNode.getCell(1, 0).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {
              "insert": "3",
            }
          ]
        },
      );

      expect(
        tableNode.getCell(1, 1).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {"insert": "4"}
          ]
        },
      );
    });

    test('default constructor (from list of list of strings)', () {
      const config = TableConfig(
          colMinimumWidth: 10, colDefaultWidth: 20, rowDefaultHeight: 30);
      final tableNode = TableNode.fromList([
        ['1', '2'],
        ['3', '4']
      ], config: config);

      expect(tableNode.config.colMinimumWidth, config.colMinimumWidth);
      expect(tableNode.config.colDefaultWidth, config.colDefaultWidth);
      expect(tableNode.config.rowDefaultHeight, config.rowDefaultHeight);

      expect(tableNode.getColWidth(0), config.colDefaultWidth);

      expect(tableNode.getRowHeight(1), config.rowDefaultHeight);

      expect(
        tableNode.getCell(1, 0).children.first.toJson(),
        {
          "type": "text",
          "delta": [
            {
              "insert": "3",
            }
          ]
        },
      );
    });

    test(
        'default constructor (from list of list of strings) - error when columns length mismatch',
        () {
      final listData = [
        ['1', '2'],
        ['3']
      ];

      expect(() => TableNode.fromList(listData), throwsAssertionError);
    });

    test('colsHeight', () {
      final tableNode = TableNode.fromList([
        ['1', '2'],
        ['3', '4']
      ]);

      expect(
          tableNode.colsHeight,
          tableNode.config.rowDefaultHeight * 2 +
              tableNode.config.tableBorderWidth * 3);
    });
  });
}

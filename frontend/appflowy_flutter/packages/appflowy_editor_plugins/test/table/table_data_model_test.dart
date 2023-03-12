import 'package:appflowy_editor_plugins/src/table/src/table_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_data_model.dart';

void main() {
  group('table_data_model.dart', () {
    test('fromJson', () {
      final tableData = TableData.fromJson({
        'config': {
          'colDefaultWidth': 60,
          'rowDefaultHeight': 50,
          'colMinimumWidth': 30,
        },
        'columns': [
          {
            'width': 35,
            'cells': [
              {
                'type': 'text',
                "attributes": {"subtype": "heading", "heading": "h2"},
                "delta": [
                  {"insert": "a"}
                ]
              },
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
            'cells': [
              {
                "type": "text",
                "delta": [
                  {
                    "insert": "c",
                    "attributes": {"italic": true}
                  }
                ]
              },
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

      expect(tableData.config.colMinimumWidth, 30);
      expect(tableData.config.colDefaultWidth, 60);
      expect(tableData.config.rowDefaultHeight, 50);

      expect(tableData.getColWidth(0), 35);
      expect(tableData.getColWidth(1), tableData.config.colDefaultWidth);

      expect(tableData.getRowHeight(0), tableData.config.rowDefaultHeight);
      expect(tableData.getRowHeight(1), tableData.config.rowDefaultHeight);

      expect(
        tableData.getCell(0, 0),
        {
          'type': 'text',
          "attributes": {"subtype": "heading", "heading": "h2"},
          "delta": [
            {"insert": "a"}
          ]
        },
      );
      expect(
        tableData.getCell(1, 0),
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
        tableData.getCell(1, 1),
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
        'config': {
          'colDefaultWidth': 60,
          'rowDefaultHeight': 50,
          'colMinimumWidth': 30,
        },
        'columns': [
          {
            'width': 35,
            'cells': [
              {
                'type': 'text',
                "delta": [
                  {"insert": "a"}
                ]
              },
              {
                "type": "text",
                "delta": [
                  {"insert": "b"}
                ]
              },
            ],
          },
          {
            'cells': [
              {
                "type": "text",
                "delta": [
                  {"insert": "c"}
                ]
              },
            ]
          }
        ],
      };

      expect(() => TableData.fromJson(jsonData), throwsAssertionError);
    });
    test('fromJson - error when 0 cells', () {
      var jsonData = {
        'config': {
          'colDefaultWidth': 60,
          'rowDefaultHeight': 50,
          'colMinimumWidth': 30,
        },
        'columns': [],
      };
      expect(() => TableData.fromJson(jsonData), throwsAssertionError);

      jsonData = {
        'config': {
          'colDefaultWidth': 60,
          'rowDefaultHeight': 50,
          'colMinimumWidth': 30,
        },
        'columns': [
          {
            'width': 35,
            'cells': [],
          },
        ],
      };
      expect(() => TableData.fromJson(jsonData), throwsAssertionError);
    });

    test('default constructor (from list of list of strings)', () {
      final tableData = TableData([
        ['1', '2'],
        ['3', '4']
      ]);
      const config = TableConfig();

      expect(tableData.config.colMinimumWidth, config.colMinimumWidth);
      expect(tableData.config.colDefaultWidth, config.colDefaultWidth);
      expect(tableData.config.rowDefaultHeight, config.rowDefaultHeight);

      expect(tableData.getColWidth(0), config.colDefaultWidth);
      expect(tableData.getColWidth(1), config.colDefaultWidth);

      expect(tableData.getRowHeight(0), config.rowDefaultHeight);
      expect(tableData.getRowHeight(1), config.rowDefaultHeight);

      expect(
        tableData.getCell(0, 0),
        {
          'type': 'text',
          "delta": [
            {"insert": "1"}
          ]
        },
      );
      expect(
        tableData.getCell(1, 0),
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
        tableData.getCell(1, 1),
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
      final tableData = TableData([
        ['1', '2'],
        ['3', '4']
      ], config: config);

      expect(tableData.config.colMinimumWidth, config.colMinimumWidth);
      expect(tableData.config.colDefaultWidth, config.colDefaultWidth);
      expect(tableData.config.rowDefaultHeight, config.rowDefaultHeight);

      expect(tableData.getColWidth(0), config.colDefaultWidth);

      expect(tableData.getRowHeight(1), config.rowDefaultHeight);

      expect(
        tableData.getCell(1, 0),
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

      expect(() => TableData(listData), throwsAssertionError);
    });

    test('toJson', () {
      final jsonData = {
        'columns': [
          {
            'width': 35,
            'cells': [
              {
                'type': 'text',
                "attributes": {"subtype": "heading", "heading": "h2"},
                "delta": [
                  {"insert": "a"}
                ]
              },
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
            'cells': [
              {
                "type": "text",
                "delta": [
                  {
                    "insert": "c",
                    "attributes": {"italic": true}
                  }
                ]
              },
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

      final tableData = TableData.fromJson(jsonData);
      final json = tableData.toJson();

      expect(json['config'], {
        'colDefaultWidth': tableData.config.colDefaultWidth,
        'rowDefaultHeight': tableData.config.rowDefaultHeight,
        'colMinimumWidth': tableData.config.colMinimumWidth,
      });
      expect(json['columns'], [
        {
          'width': 35.0,
          'cells': [
            {
              'type': 'text',
              "attributes": {"subtype": "heading", "heading": "h2"},
              "delta": [
                {"insert": "a"}
              ]
            },
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
          'width': 80.0,
          'cells': [
            {
              "type": "text",
              "delta": [
                {
                  "insert": "c",
                  "attributes": {"italic": true}
                }
              ]
            },
            {
              "type": "text",
              "delta": [
                {"insert": "d"}
              ]
            }
          ]
        }
      ]);
    });

    test('colsHeight', () {
      final tableData = TableData([
        ['1', '2'],
        ['3', '4']
      ]);

      expect(
          tableData.colsHeight,
          tableData.config.rowDefaultHeight * 2 +
              tableData.config.tableBorderWidth * 3);
    });

    test('addCol', () {
      final tableData = TableData([
        ['1', '2'],
        ['3', '4']
      ]);
      tableData.addCol();

      expect(tableData.colsLen, 3);
      expect(
        tableData.getCell(2, 1),
        {
          "type": "text",
          "delta": [
            {
              "insert": "",
            }
          ]
        },
      );
      expect(tableData.getColWidth(2), tableData.config.colDefaultWidth);
    });

    test('addRow', () {
      final tableData = TableData([
        ['1', '2'],
        ['3', '4']
      ]);
      tableData.addRow();

      expect(tableData.rowsLen, 3);
      expect(
        tableData.getCell(0, 2),
        {
          "type": "text",
          "delta": [
            {
              "insert": "",
            }
          ]
        },
      );
      expect(tableData.getRowHeight(2), tableData.config.rowDefaultHeight);
    });
  });
}

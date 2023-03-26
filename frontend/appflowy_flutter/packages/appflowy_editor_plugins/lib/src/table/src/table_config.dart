const defaultColWidth = 80.0, defaultRowHeight = 40.0, minimumColWidth = 40.0;

class TableConfig {
  const TableConfig({
    this.colDefaultWidth = defaultColWidth,
    this.rowDefaultHeight = defaultRowHeight,
    this.colMinimumWidth = minimumColWidth,
  });

  static TableConfig fromJson(Map<String, dynamic> json) {
    func(String key, double defaultVal) => json.containsKey(key)
        ? double.tryParse(json[key].toString())!
        : defaultVal;

    return TableConfig(
      colDefaultWidth: func('colDefaultWidth', defaultColWidth),
      rowDefaultHeight: func('rowDefaultHeight', defaultRowHeight),
      colMinimumWidth: func('colMinimumWidth', minimumColWidth),
    );
  }

  Map<String, Object> toJson() {
    return {
      'colDefaultWidth': colDefaultWidth,
      'rowDefaultHeight': rowDefaultHeight,
      'colMinimumWidth': colMinimumWidth,
    };
  }

  final double colDefaultWidth, rowDefaultHeight, colMinimumWidth;

  final double tableBorderWidth = 2.0;

  clone() => TableConfig(
        colDefaultWidth: colDefaultWidth,
        rowDefaultHeight: rowDefaultHeight,
        colMinimumWidth: colMinimumWidth,
      );
}

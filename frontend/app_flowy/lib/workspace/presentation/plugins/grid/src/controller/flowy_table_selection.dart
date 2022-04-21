/// The data structor representing each selection of flowy table.
enum FlowyTableSelectionType {
  item,
  row,
  col,
}

class FlowyTableSelectionItem {
  final FlowyTableSelectionType type;
  final int? row;
  final int? column;

  const FlowyTableSelectionItem({
    required this.type,
    this.row,
    this.column,
  });

  @override
  String toString() {
    return '$type($row, $column)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is FlowyTableSelectionItem &&
        type == other.type &&
        row == other.row &&
        column == other.column;
  }

  @override
  int get hashCode => type.hashCode ^ row.hashCode ^ column.hashCode;
}

class FlowyTableSelection {
  Set<FlowyTableSelectionItem> _items = {};

  Set<FlowyTableSelectionItem> get items => _items;

  FlowyTableSelection(
    this._items,
  );

  FlowyTableSelection.combine(
      FlowyTableSelection lhs, FlowyTableSelection rhs) {
    this..combine(lhs)..combine(rhs);
  }

  FlowyTableSelection operator +(FlowyTableSelection other) {
    return this..combine(other);
  }

  void combine(FlowyTableSelection other) {
    var totalItems = items..union(other.items);
    final rows = totalItems
        .where((ele) => ele.type == FlowyTableSelectionType.row)
        .map((e) => e.row)
        .toSet();
    final cols = totalItems
        .where((ele) => ele.type == FlowyTableSelectionType.col)
        .map((e) => e.column)
        .toSet();
    totalItems.removeWhere((ele) {
      return ele.type == FlowyTableSelectionType.item &&
          (rows.contains(ele.row) || cols.contains(ele.column));
    });
    _items = totalItems;
  }
}

import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:flutter_test/flutter_test.dart';

extension GridTestExtensions on WidgetTester {
  List<RowId> getGridRows() {
    final databaseController =
        widget<GridPage>(find.byType(GridPage)).databaseController;
    return [
      ...databaseController.rowCache.rowInfos.map((e) => e.rowId),
    ];
  }
}

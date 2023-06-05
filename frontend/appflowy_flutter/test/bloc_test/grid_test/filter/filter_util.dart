import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/grid/grid.dart';
import 'package:appflowy/workspace/application/app/app_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pbenum.dart';

import '../util.dart';

Future<GridTestContext> createTestFilterGrid(final AppFlowyGridTest gridTest) async {
  final app = await gridTest.unitTest.createTestApp();
  final builder = GridPluginBuilder();
  final context = await AppBackendService()
      .createView(
    appId: app.id,
    name: "Filter Grid",
    layoutType: builder.layoutType!,
  )
      .then((final result) {
    return result.fold(
      (final view) async {
        final context = GridTestContext(
          view,
          DatabaseController(
            view: view,
            layoutType: LayoutTypePB.Grid,
          ),
        );
        final result = await context.gridController.open();

        await editCells(context);
        await gridResponseFuture(milliseconds: 500);
        result.fold((final l) => null, (final r) => throw Exception(r));
        return context;
      },
      (final error) => throw Exception(),
    );
  });

  return context;
}

Future<void> editCells(final GridTestContext context) async {
  final controller0 = await context.makeTextCellController(0);
  final controller1 = await context.makeTextCellController(1);

  controller0.saveCellData('A');
  await gridResponseFuture();
  controller1.saveCellData('B');
}

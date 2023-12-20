import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pbenum.dart';

import '../util.dart';

Future<GridTestContext> createTestFilterGrid(AppFlowyGridTest gridTest) async {
  final app = await gridTest.unitTest.createWorkspace();
  final context = await ViewBackendService.createView(
    parentViewId: app.id,
    name: "Filter Grid",
    layoutType: ViewLayoutPB.Grid,
    openAfterCreate: true,
  ).then((result) {
    return result.fold(
      (view) async {
        final context = GridTestContext(
          view,
          DatabaseController(view: view),
        );
        final result = await context.gridController.open();

        await editCells(context);
        await gridResponseFuture(milliseconds: 500);
        result.fold((l) => null, (r) => throw Exception(r));
        return context;
      },
      (error) => throw Exception(),
    );
  });

  return context;
}

Future<void> editCells(GridTestContext context) async {
  final controller0 = await context.makeTextCellController(0);
  final controller1 = await context.makeTextCellController(1);

  controller0.saveCellData('A');
  await gridResponseFuture();
  controller1.saveCellData('B');
}

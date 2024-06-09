import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';

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
        result.fold((l) => null, (r) => throw Exception(r));
        return context;
      },
      (error) => throw Exception(),
    );
  });

  return context;
}

Future<void> editCells(GridTestContext context) async {
  final controller0 = context.makeTextCellController(0);
  final controller1 = context.makeTextCellController(1);

  await controller0.saveCellData('A');
  await gridResponseFuture();
  await controller1.saveCellData('B');
  await gridResponseFuture();
}

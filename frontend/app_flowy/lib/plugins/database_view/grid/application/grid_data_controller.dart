import 'package:app_flowy/plugins/database_view/application/field/field_controller.dart';
import 'package:app_flowy/plugins/database_view/application/view/view_cache.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../application/database_service.dart';
import '../../application/defines.dart';
import '../../application/row/row_cache.dart';

typedef OnRowsChanged = void Function(
  List<RowInfo> rowInfos,
  RowsChangedReason,
);
typedef ListenOnRowChangedCondition = bool Function();

class DatabaseController {
  final String viewId;
  final DatabaseBackendService _databaseBackendSvc;
  final FieldController fieldController;
  late DatabaseViewCache _viewCache;

  OnRowsChanged? _onRowChanged;
  OnDatabaseChanged? _onGridChanged;
  List<RowInfo> get rowInfos => _viewCache.rowInfos;
  RowCache get rowCache => _viewCache.rowCache;

  DatabaseController({required ViewPB view})
      : viewId = view.id,
        _databaseBackendSvc = DatabaseBackendService(viewId: view.id),
        fieldController = FieldController(viewId: view.id) {
    _viewCache = DatabaseViewCache(
      viewId: viewId,
      fieldController: fieldController,
    );
    _viewCache.addListener(onRowsChanged: (reason) {
      _onRowChanged?.call(rowInfos, reason);
    });
  }

  void addListener({
    OnDatabaseChanged? onGridChanged,
    OnRowsChanged? onRowsChanged,
    OnFieldsChanged? onFieldsChanged,
    OnFiltersChanged? onFiltersChanged,
  }) {
    _onGridChanged = onGridChanged;
    _onRowChanged = onRowsChanged;

    fieldController.addListener(
      onFields: (fields) {
        onFieldsChanged?.call(UnmodifiableListView(fields));
      },
      onFilters: onFiltersChanged,
    );
  }

  Future<Either<Unit, FlowyError>> openGrid() async {
    return _databaseBackendSvc.openGrid().then((result) {
      return result.fold(
        (grid) async {
          _onGridChanged?.call(grid);
          _viewCache.rowCache.initializeRows(grid.rows);
          final result = await fieldController.loadFields(
            fieldIds: grid.fields,
          );
          return result;
        },
        (err) => right(err),
      );
    });
  }

  Future<void> createRow() async {
    await _databaseBackendSvc.createRow();
  }

  Future<void> dispose() async {
    await _databaseBackendSvc.closeGrid();
    await fieldController.dispose();
  }
}

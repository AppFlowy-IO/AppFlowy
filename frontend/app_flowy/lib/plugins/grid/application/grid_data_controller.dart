import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/grid_entities.pb.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'view/grid_view_cache.dart';
import 'field/field_controller.dart';
import 'prelude.dart';
import 'row/row_cache.dart';

typedef OnFieldsChanged = void Function(List<FieldInfo>);
typedef OnFiltersChanged = void Function(List<FilterInfo>);
typedef OnGridChanged = void Function(GridPB);

typedef OnRowsChanged = void Function(
  List<RowInfo> rowInfos,
  RowsChangedReason,
);
typedef ListenOnRowChangedCondition = bool Function();

class GridController {
  final String gridId;
  final GridFFIService _gridFFIService;
  final GridFieldController fieldController;
  late GridViewCache _viewCache;

  OnRowsChanged? _onRowChanged;
  OnGridChanged? _onGridChanged;
  List<RowInfo> get rowInfos => _viewCache.rowInfos;
  GridRowCache get rowCache => _viewCache.rowCache;

  GridController({required ViewPB view})
      : gridId = view.id,
        _gridFFIService = GridFFIService(gridId: view.id),
        fieldController = GridFieldController(gridId: view.id) {
    _viewCache = GridViewCache(
      gridId: gridId,
      fieldController: fieldController,
    );
    _viewCache.addListener(onRowsChanged: (reason) {
      _onRowChanged?.call(rowInfos, reason);
    });
  }

  void addListener({
    OnGridChanged? onGridChanged,
    OnRowsChanged? onRowsChanged,
    OnFieldsChanged? onFieldsChanged,
    OnFiltersChanged? onFiltersChanged,
  }) {
    _onGridChanged = onGridChanged;
    _onRowChanged = onRowsChanged;

    fieldController.addListener(
      onFields: onFieldsChanged,
      onFilters: onFiltersChanged,
    );
  }

  // Loads the rows from each block
  Future<Either<Unit, FlowyError>> openGrid() async {
    return _gridFFIService.openGrid().then((result) {
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
    await _gridFFIService.createRow();
  }

  Future<void> dispose() async {
    await _gridFFIService.closeGrid();
    await fieldController.dispose();
  }
}

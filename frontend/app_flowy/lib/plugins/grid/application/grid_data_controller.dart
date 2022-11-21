import 'dart:collection';

import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'block/block_cache.dart';
import 'field/field_controller.dart';
import 'prelude.dart';
import 'row/row_cache.dart';

typedef OnFieldsChanged = void Function(List<GridFieldInfo>);
typedef OnFiltersChanged = void Function(List<FilterPB>);
typedef OnGridChanged = void Function(GridPB);

typedef OnRowsChanged = void Function(
  List<RowInfo> rowInfos,
  RowsChangedReason,
);
typedef ListenOnRowChangedCondition = bool Function();

class GridDataController {
  final String gridId;
  final GridFFIService _gridFFIService;
  final GridFieldController fieldController;
  OnRowsChanged? _onRowChanged;
  OnGridChanged? _onGridChanged;

  // Getters
  // key: the block id
  final LinkedHashMap<String, GridBlockCache> _blocks;
  UnmodifiableMapView<String, GridBlockCache> get blocks =>
      UnmodifiableMapView(_blocks);

  List<RowInfo> get rowInfos {
    final List<RowInfo> rows = [];
    for (var block in _blocks.values) {
      rows.addAll(block.rows);
    }
    return rows;
  }

  GridDataController({required ViewPB view})
      : gridId = view.id,
        // ignore: prefer_collection_literals
        _blocks = LinkedHashMap(),
        _gridFFIService = GridFFIService(gridId: view.id),
        fieldController = GridFieldController(gridId: view.id);

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
    final result = await _gridFFIService.openGrid();
    return Future(
      () => result.fold(
        (grid) async {
          _initialBlocks(grid.blocks);
          _onGridChanged?.call(grid);
          return await fieldController.loadFields(fieldIds: grid.fields);
        },
        (err) => right(err),
      ),
    );
  }

  Future<void> createRow() async {
    await _gridFFIService.createRow();
  }

  Future<void> dispose() async {
    await _gridFFIService.closeGrid();
    await fieldController.dispose();

    for (final blockCache in _blocks.values) {
      blockCache.dispose();
    }
  }

  void _initialBlocks(List<BlockPB> blocks) {
    for (final block in blocks) {
      if (_blocks[block.id] != null) {
        Log.warn("Initial duplicate block's cache: ${block.id}");
        return;
      }

      final cache = GridBlockCache(
        gridId: gridId,
        block: block,
        fieldController: fieldController,
      );

      cache.addListener(onRowsChanged: (reason) {
        _onRowChanged?.call(rowInfos, reason);
      });

      _blocks[block.id] = cache;
    }
  }
}

import 'dart:collection';

import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'block/block_cache.dart';
import 'field/field_cache.dart';
import 'prelude.dart';
import 'row/row_cache.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<FieldPB>);
typedef OnGridChanged = void Function(GridPB);

typedef OnRowsChanged = void Function(
  List<RowInfo> rowInfos,
  RowChangeReason,
);
typedef ListenONRowChangedCondition = bool Function();

class GridDataController {
  final String gridId;
  final GridService _gridFFIService;
  final GridFieldCache fieldCache;

  // key: the block id
  final LinkedHashMap<String, GridBlockCache> _blocks;
  UnmodifiableMapView<String, GridBlockCache> get blocks =>
      UnmodifiableMapView(_blocks);

  OnRowsChanged? _onRowChanged;
  OnFieldsChanged? _onFieldsChanged;
  OnGridChanged? _onGridChanged;

  List<RowInfo> get rowInfos {
    final List<RowInfo> rows = [];
    for (var block in _blocks.values) {
      rows.addAll(block.rows);
    }
    return rows;
  }

  GridDataController({required ViewPB view})
      : gridId = view.id,
        _blocks = LinkedHashMap.identity(),
        _gridFFIService = GridService(gridId: view.id),
        fieldCache = GridFieldCache(gridId: view.id);

  void addListener({
    required OnGridChanged onGridChanged,
    required OnRowsChanged onRowsChanged,
    required OnFieldsChanged onFieldsChanged,
  }) {
    _onGridChanged = onGridChanged;
    _onRowChanged = onRowsChanged;
    _onFieldsChanged = onFieldsChanged;

    fieldCache.addListener(onFields: (fields) {
      _onFieldsChanged?.call(UnmodifiableListView(fields));
    });
  }

  Future<Either<Unit, FlowyError>> loadData() async {
    final result = await _gridFFIService.loadGrid();
    return Future(
      () => result.fold(
        (grid) async {
          _initialBlocks(grid.blocks);
          _onGridChanged?.call(grid);
          return await _loadFields(grid);
        },
        (err) => right(err),
      ),
    );
  }

  void createRow() {
    _gridFFIService.createRow();
  }

  Future<void> dispose() async {
    await _gridFFIService.closeGrid();
    await fieldCache.dispose();

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
        fieldCache: fieldCache,
      );

      cache.addListener(
        onChangeReason: (reason) {
          _onRowChanged?.call(rowInfos, reason);
        },
      );

      _blocks[block.id] = cache;
    }
  }

  Future<Either<Unit, FlowyError>> _loadFields(GridPB grid) async {
    final result = await _gridFFIService.getFields(fieldIds: grid.fields);
    return Future(
      () => result.fold(
        (fields) {
          fieldCache.fields = fields.items;
          _onFieldsChanged?.call(UnmodifiableListView(fieldCache.fields));
          return left(unit);
        },
        (err) => right(err),
      ),
    );
  }
}

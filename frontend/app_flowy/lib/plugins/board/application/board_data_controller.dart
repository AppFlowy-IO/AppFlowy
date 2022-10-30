import 'dart:collection';

import 'package:app_flowy/plugins/grid/application/block/block_cache.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/grid_service.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';

import 'board_listener.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<GridFieldContext>);
typedef OnGridChanged = void Function(GridPB);
typedef DidLoadGroups = void Function(List<GroupPB>);
typedef OnUpdatedGroup = void Function(List<GroupPB>);
typedef OnDeletedGroup = void Function(List<String>);
typedef OnInsertedGroup = void Function(List<InsertedGroupPB>);
typedef OnResetGroups = void Function(List<GroupPB>);

typedef OnRowsChanged = void Function(
  List<RowInfo>,
  RowsChangedReason,
);
typedef OnError = void Function(FlowyError);

class BoardDataController {
  final String gridId;
  final GridFFIService _gridFFIService;
  final GridFieldController fieldController;
  final BoardListener _listener;

  // key: the block id
  final LinkedHashMap<String, GridBlockCache> _blocks;
  UnmodifiableMapView<String, GridBlockCache> get blocks =>
      UnmodifiableMapView(_blocks);

  OnFieldsChanged? _onFieldsChanged;
  OnGridChanged? _onGridChanged;
  DidLoadGroups? _didLoadGroup;
  OnRowsChanged? _onRowsChanged;
  OnError? _onError;

  List<RowInfo> get rowInfos {
    final List<RowInfo> rows = [];
    for (var block in _blocks.values) {
      rows.addAll(block.rows);
    }
    return rows;
  }

  BoardDataController({required ViewPB view})
      : gridId = view.id,
        _listener = BoardListener(view.id),
        // ignore: prefer_collection_literals
        _blocks = LinkedHashMap(),
        _gridFFIService = GridFFIService(gridId: view.id),
        fieldController = GridFieldController(gridId: view.id);

  void addListener({
    required OnGridChanged onGridChanged,
    OnFieldsChanged? onFieldsChanged,
    required DidLoadGroups didLoadGroups,
    OnRowsChanged? onRowsChanged,
    required OnUpdatedGroup onUpdatedGroup,
    required OnDeletedGroup onDeletedGroup,
    required OnInsertedGroup onInsertedGroup,
    required OnResetGroups onResetGroups,
    required OnError? onError,
  }) {
    _onGridChanged = onGridChanged;
    _onFieldsChanged = onFieldsChanged;
    _didLoadGroup = didLoadGroups;
    _onRowsChanged = onRowsChanged;
    _onError = onError;

    fieldController.addListener(onFields: (fields) {
      _onFieldsChanged?.call(UnmodifiableListView(fields));
    });

    _listener.start(
      onBoardChanged: (result) {
        result.fold(
          (changeset) {
            if (changeset.updateGroups.isNotEmpty) {
              onUpdatedGroup.call(changeset.updateGroups);
            }

            if (changeset.deletedGroups.isNotEmpty) {
              onDeletedGroup.call(changeset.deletedGroups);
            }

            if (changeset.insertedGroups.isNotEmpty) {
              onInsertedGroup.call(changeset.insertedGroups);
            }
          },
          (e) => _onError?.call(e),
        );
      },
      onGroupByNewField: (result) {
        result.fold(
          (groups) => onResetGroups(groups),
          (e) => _onError?.call(e),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> openGrid() async {
    final result = await _gridFFIService.openGrid();
    return Future(
      () => result.fold(
        (grid) async {
          _onGridChanged?.call(grid);
          final result = await fieldController.loadFields(
            fieldIds: grid.fields,
          );
          return result.fold(
            (l) {
              _loadGroups(grid.blocks);
              return left(l);
            },
            (err) => right(err),
          );
        },
        (err) => right(err),
      ),
    );
  }

  Future<Either<RowPB, FlowyError>> createBoardCard(String groupId,
      {String? startRowId}) {
    return _gridFFIService.createBoardCard(groupId, startRowId);
  }

  Future<void> dispose() async {
    await _gridFFIService.closeGrid();
    await fieldController.dispose();

    for (final blockCache in _blocks.values) {
      blockCache.dispose();
    }
  }

  Future<void> _loadGroups(List<BlockPB> blocks) async {
    for (final block in blocks) {
      final cache = GridBlockCache(
        gridId: gridId,
        block: block,
        fieldController: fieldController,
      );

      cache.addListener(onRowsChanged: (reason) {
        _onRowsChanged?.call(rowInfos, reason);
      });
      _blocks[block.id] = cache;
    }

    final result = await _gridFFIService.loadGroups();
    return Future(
      () => result.fold(
        (groups) {
          _didLoadGroup?.call(groups.items);
        },
        (err) => _onError?.call(err),
      ),
    );
  }
}

import 'dart:collection';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';

import '../../application/database_service.dart';
import '../../application/defines.dart';
import '../../application/field/field_controller.dart';
import '../../application/row/row_cache.dart';
import '../../application/view/view_cache.dart';
import 'board_listener.dart';

typedef DidLoadGroups = void Function(List<GroupPB>);
typedef OnUpdatedGroup = void Function(List<GroupPB>);
typedef OnDeletedGroup = void Function(List<String>);
typedef OnInsertedGroup = void Function(InsertedGroupPB);
typedef OnResetGroups = void Function(List<GroupPB>);

class BoardDataController {
  final String viewId;
  final DatabaseBackendService _databaseFFIService;
  final FieldController fieldController;
  final BoardListener _listener;
  late DatabaseViewCache _viewCache;

  OnFieldsChanged? _onFieldsChanged;
  OnDatabaseChanged? _onDatabaseChanged;
  DidLoadGroups? _didLoadGroup;
  OnRowsChanged? _onRowsChanged;
  OnError? _onError;

  List<RowInfo> get rowInfos => _viewCache.rowInfos;
  RowCache get rowCache => _viewCache.rowCache;

  BoardDataController({required ViewPB view})
      : viewId = view.id,
        _listener = BoardListener(view.id),
        _databaseFFIService = DatabaseBackendService(viewId: view.id),
        fieldController = FieldController(viewId: view.id) {
    //
    _viewCache = DatabaseViewCache(
      viewId: view.id,
      fieldController: fieldController,
    );
    _viewCache.addListener(onRowsChanged: (reason) {
      _onRowsChanged?.call(rowInfos, reason);
    });
  }

  void addListener({
    required OnDatabaseChanged onDatabaseChanged,
    OnFieldsChanged? onFieldsChanged,
    required DidLoadGroups didLoadGroups,
    OnRowsChanged? onRowsChanged,
    required OnUpdatedGroup onUpdatedGroup,
    required OnDeletedGroup onDeletedGroup,
    required OnInsertedGroup onInsertedGroup,
    required OnResetGroups onResetGroups,
    required OnError? onError,
  }) {
    _onDatabaseChanged = onDatabaseChanged;
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

            for (final insertedGroup in changeset.insertedGroups) {
              onInsertedGroup.call(insertedGroup);
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
    final result = await _databaseFFIService.openGrid();
    return result.fold(
      (grid) async {
        _onDatabaseChanged?.call(grid);
        return fieldController.loadFields(fieldIds: grid.fields).then((result) {
          return result.fold(
            (l) => Future(() async {
              await _loadGroups();
              _viewCache.rowCache.initializeRows(grid.rows);
              return left(l);
            }),
            (err) => right(err),
          );
        });
      },
      (err) => right(err),
    );
  }

  Future<Either<RowPB, FlowyError>> createBoardCard(String groupId,
      {String? startRowId}) {
    return _databaseFFIService.createBoardCard(groupId, startRowId);
  }

  Future<void> dispose() async {
    await _viewCache.dispose();
    await _databaseFFIService.closeGrid();
    await fieldController.dispose();
  }

  Future<void> _loadGroups() async {
    final result = await _databaseFFIService.loadGroups();
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

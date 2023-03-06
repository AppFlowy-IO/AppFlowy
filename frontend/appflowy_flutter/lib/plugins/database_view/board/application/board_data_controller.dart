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

typedef OnGroupByField = void Function(List<GroupPB>);
typedef OnUpdatedGroup = void Function(List<GroupPB>);
typedef OnDeletedGroup = void Function(List<String>);
typedef OnInsertedGroup = void Function(InsertedGroupPB);
typedef OnResetGroups = void Function(List<GroupPB>);

class BoardDataController {
  final String viewId;
  final DatabaseBackendService _databaseSvc;
  final FieldController fieldController;
  final DatabaseGroupListener _listener;
  late DatabaseViewCache _viewCache;

  OnFieldsChanged? _onFieldsChanged;
  OnDatabaseChanged? _onDatabaseChanged;
  OnGroupByField? _onGroupByField;
  OnRowsChanged? _onRowsChanged;
  OnError? _onError;

  List<RowInfo> get rowInfos => _viewCache.rowInfos;
  RowCache get rowCache => _viewCache.rowCache;

  BoardDataController({required ViewPB view})
      : viewId = view.id,
        _listener = DatabaseGroupListener(view.id),
        _databaseSvc = DatabaseBackendService(viewId: view.id),
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
    required OnGroupByField onGroupByField,
    OnRowsChanged? onRowsChanged,
    required OnUpdatedGroup onUpdatedGroup,
    required OnDeletedGroup onDeletedGroup,
    required OnInsertedGroup onInsertedGroup,
    required OnError? onError,
  }) {
    _onDatabaseChanged = onDatabaseChanged;
    _onFieldsChanged = onFieldsChanged;
    _onGroupByField = onGroupByField;
    _onRowsChanged = onRowsChanged;
    _onError = onError;

    fieldController.addListener(onReceiveFields: (fields) {
      _onFieldsChanged?.call(UnmodifiableListView(fields));
    });

    _listener.start(
      onNumOfGroupsChanged: (result) {
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
          (groups) => onGroupByField(groups),
          (e) => _onError?.call(e),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> openGrid() async {
    final result = await _databaseSvc.openGrid();
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
    return _databaseSvc.createBoardCard(groupId, startRowId);
  }

  Future<void> dispose() async {
    await _viewCache.dispose();
    await _databaseSvc.closeView();
    await fieldController.dispose();
  }

  Future<void> _loadGroups() async {
    final result = await _databaseSvc.loadGroups();
    return Future(
      () => result.fold(
        (groups) {
          _onGroupByField?.call(groups.items);
        },
        (err) => _onError?.call(err),
      ),
    );
  }
}

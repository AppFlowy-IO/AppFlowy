import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/view/view_cache.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../application/database_service.dart';
import '../../application/defines.dart';
import '../../application/row/row_cache.dart';
import '../../board/application/board_listener.dart';

typedef OnRowsChanged = void Function(
  List<RowInfo> rowInfos,
  RowsChangedReason,
);

typedef OnGroupByField = void Function(List<GroupPB>);
typedef OnUpdateGroup = void Function(List<GroupPB>);
typedef OnDeleteGroup = void Function(List<String>);
typedef OnInsertGroup = void Function(InsertedGroupPB);

class GroupCallbacks {
  final OnGroupByField? onGroupByField;
  final OnUpdateGroup? onUpdateGroup;
  final OnDeleteGroup? onDeleteGroup;
  final OnInsertGroup? onInsertGroup;

  GroupCallbacks(
    this.onGroupByField,
    this.onUpdateGroup,
    this.onDeleteGroup,
    this.onInsertGroup,
  );
}

class DatabaseController {
  final String viewId;
  final DatabaseBackendService _databaseBackendSvc;
  final FieldController fieldController;
  late DatabaseViewCache _viewCache;

  // Callbacks
  OnRowsChanged? _onRowChanged;
  OnDatabaseChanged? _onDatabaseChanged;
  GroupCallbacks? _groupCallbacks;

  // Getters
  List<RowInfo> get rowInfos => _viewCache.rowInfos;
  RowCache get rowCache => _viewCache.rowCache;

// Listener
  final DatabaseGroupListener groupListener;

  DatabaseController({required ViewPB view})
      : viewId = view.id,
        _databaseBackendSvc = DatabaseBackendService(viewId: view.id),
        fieldController = FieldController(viewId: view.id),
        groupListener = DatabaseGroupListener(view.id) {
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
    GroupCallbacks? onGroupChanged,
  }) {
    _onDatabaseChanged = onGridChanged;
    _onRowChanged = onRowsChanged;

    fieldController.addListener(
      onReceiveFields: (fields) {
        onFieldsChanged?.call(UnmodifiableListView(fields));
      },
      onFilters: onFiltersChanged,
    );
  }

  Future<Either<Unit, FlowyError>> openGrid() async {
    return _databaseBackendSvc.openGrid().then((result) {
      return result.fold(
        (database) async {
          _onDatabaseChanged?.call(database);
          _viewCache.rowCache.initializeRows(database.rows);
          await _loadGroups();
          return await fieldController.loadFields(
            fieldIds: database.fields,
          );
        },
        (err) => right(err),
      );
    });
  }

  Future<void> createRow() async {
    await _databaseBackendSvc.createRow();
  }

  Future<void> dispose() async {
    await _databaseBackendSvc.closeView();
    await fieldController.dispose();
  }

  Future<void> _loadGroups() async {
    final result = await _databaseBackendSvc.loadGroups();
    return Future(
      () => result.fold(
        (groups) {
          _groupCallbacks?.onGroupByField?.call(groups.items);
        },
        (err) => Log.error(err),
      ),
    );
  }
}

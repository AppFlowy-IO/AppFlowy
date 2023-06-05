import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/layout/calendar_setting_listener.dart';
import 'package:appflowy/plugins/database_view/application/view/view_cache.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'database_view_service.dart';
import 'defines.dart';
import 'layout/layout_setting_listener.dart';
import 'row/row_cache.dart';
import 'group/group_listener.dart';

typedef OnGroupByField = void Function(List<GroupPB>);
typedef OnUpdateGroup = void Function(List<GroupPB>);
typedef OnDeleteGroup = void Function(List<String>);
typedef OnInsertGroup = void Function(InsertedGroupPB);

class GroupCallbacks {
  final OnGroupByField? onGroupByField;
  final OnUpdateGroup? onUpdateGroup;
  final OnDeleteGroup? onDeleteGroup;
  final OnInsertGroup? onInsertGroup;

  GroupCallbacks({
    this.onGroupByField,
    this.onUpdateGroup,
    this.onDeleteGroup,
    this.onInsertGroup,
  });
}

class LayoutCallbacks {
  final void Function(LayoutSettingPB) onLayoutChanged;
  final void Function(LayoutSettingPB) onLoadLayout;

  LayoutCallbacks({
    required this.onLayoutChanged,
    required this.onLoadLayout,
  });
}

class CalendarLayoutCallbacks {
  final void Function(LayoutSettingPB) onCalendarLayoutChanged;

  CalendarLayoutCallbacks({required this.onCalendarLayoutChanged});
}

class DatabaseCallbacks {
  OnDatabaseChanged? onDatabaseChanged;
  OnFieldsChanged? onFieldsChanged;
  OnFiltersChanged? onFiltersChanged;
  OnRowsChanged? onRowsChanged;
  OnRowsDeleted? onRowsDeleted;
  OnRowsUpdated? onRowsUpdated;
  OnRowsCreated? onRowsCreated;

  DatabaseCallbacks({
    this.onDatabaseChanged,
    this.onRowsChanged,
    this.onFieldsChanged,
    this.onFiltersChanged,
    this.onRowsUpdated,
    this.onRowsDeleted,
    this.onRowsCreated,
  });
}

class DatabaseController {
  final String viewId;
  final DatabaseViewBackendService _databaseViewBackendSvc;
  final FieldController fieldController;
  late DatabaseViewCache _viewCache;
  final LayoutTypePB layoutType;

  // Callbacks
  DatabaseCallbacks? _databaseCallbacks;
  GroupCallbacks? _groupCallbacks;
  LayoutCallbacks? _layoutCallbacks;
  CalendarLayoutCallbacks? _calendarLayoutCallbacks;

  // Getters
  RowCache get rowCache => _viewCache.rowCache;

  // Listener
  final DatabaseGroupListener groupListener;
  final DatabaseLayoutListener layoutListener;
  final DatabaseCalendarLayoutListener calendarLayoutListener;

  DatabaseController({required final ViewPB view, required this.layoutType})
      : viewId = view.id,
        _databaseViewBackendSvc = DatabaseViewBackendService(viewId: view.id),
        fieldController = FieldController(viewId: view.id),
        groupListener = DatabaseGroupListener(view.id),
        layoutListener = DatabaseLayoutListener(view.id),
        calendarLayoutListener = DatabaseCalendarLayoutListener(view.id) {
    _viewCache = DatabaseViewCache(
      viewId: viewId,
      fieldController: fieldController,
    );
    _listenOnRowsChanged();
    _listenOnFieldsChanged();
    _listenOnGroupChanged();
    _listenOnLayoutChanged();
    if (layoutType == LayoutTypePB.Calendar) {
      _listenOnCalendarLayoutChanged();
    }
  }

  void setListener({
    final DatabaseCallbacks? onDatabaseChanged,
    final LayoutCallbacks? onLayoutChanged,
    final GroupCallbacks? onGroupChanged,
    final CalendarLayoutCallbacks? onCalendarLayoutChanged,
  }) {
    _layoutCallbacks = onLayoutChanged;
    _databaseCallbacks = onDatabaseChanged;
    _groupCallbacks = onGroupChanged;
    _calendarLayoutCallbacks = onCalendarLayoutChanged;
  }

  Future<Either<Unit, FlowyError>> open() async {
    return _databaseViewBackendSvc.openGrid().then((final result) {
      return result.fold(
        (final database) async {
          _databaseCallbacks?.onDatabaseChanged?.call(database);
          _viewCache.rowCache.setInitialRows(database.rows);
          return await fieldController
              .loadFields(
            fieldIds: database.fields,
          )
              .then(
            (final result) {
              return result.fold(
                (final l) => Future(() async {
                  await _loadGroups();
                  await _loadLayoutSetting();
                  return left(l);
                }),
                (final err) => right(err),
              );
            },
          );
        },
        (final err) => right(err),
      );
    });
  }

  Future<Either<RowPB, FlowyError>> createRow({
    final String? startRowId,
    final String? groupId,
    final void Function(RowDataBuilder builder)? withCells,
  }) {
    Map<String, String>? cellDataByFieldId;

    if (withCells != null) {
      final rowBuilder = RowDataBuilder();
      withCells(rowBuilder);
      cellDataByFieldId = rowBuilder.build();
    }

    return _databaseViewBackendSvc.createRow(
      startRowId: startRowId,
      groupId: groupId,
      cellDataByFieldId: cellDataByFieldId,
    );
  }

  Future<Either<Unit, FlowyError>> moveRow({
    required final RowPB fromRow,
    required final String groupId,
    final RowPB? toRow,
  }) {
    return _databaseViewBackendSvc.moveRow(
      fromRowId: fromRow.id,
      toGroupId: groupId,
      toRowId: toRow?.id,
    );
  }

  Future<Either<Unit, FlowyError>> moveGroup({
    required final String fromGroupId,
    required final String toGroupId,
  }) {
    return _databaseViewBackendSvc.moveGroup(
      fromGroupId: fromGroupId,
      toGroupId: toGroupId,
    );
  }

  Future<void> updateCalenderLayoutSetting(
    final CalendarLayoutSettingsPB layoutSetting,
  ) async {
    await _databaseViewBackendSvc
        .updateLayoutSetting(calendarLayoutSetting: layoutSetting)
        .then((final result) {
      result.fold((final l) => null, (final r) => Log.error(r));
    });
  }

  Future<void> dispose() async {
    await _databaseViewBackendSvc.closeView();
    await fieldController.dispose();
    await groupListener.stop();
    await _viewCache.dispose();
    _databaseCallbacks = null;
    _groupCallbacks = null;
    _layoutCallbacks = null;
    _calendarLayoutCallbacks = null;
  }

  Future<void> _loadGroups() async {
    final result = await _databaseViewBackendSvc.loadGroups();
    return Future(
      () => result.fold(
        (final groups) {
          _groupCallbacks?.onGroupByField?.call(groups.items);
        },
        (final err) => Log.error(err),
      ),
    );
  }

  Future<void> _loadLayoutSetting() async {
    _databaseViewBackendSvc.getLayoutSetting(layoutType).then((final result) {
      result.fold(
        (final l) {
          _layoutCallbacks?.onLoadLayout(l);
        },
        (final r) => Log.error(r),
      );
    });
  }

  void _listenOnRowsChanged() {
    final callbacks = DatabaseViewCallbacks(
      onRowsChanged: (final rows, final rowByRowId, final reason) {
        _databaseCallbacks?.onRowsChanged?.call(rows, rowByRowId, reason);
      },
      onRowsDeleted: (final ids) {
        _databaseCallbacks?.onRowsDeleted?.call(ids);
      },
      onRowsUpdated: (final ids) {
        _databaseCallbacks?.onRowsUpdated?.call(ids);
      },
      onRowsCreated: (final ids) {
        _databaseCallbacks?.onRowsCreated?.call(ids);
      },
    );
    _viewCache.setListener(callbacks);
  }

  void _listenOnFieldsChanged() {
    fieldController.addListener(
      onReceiveFields: (final fields) {
        _databaseCallbacks?.onFieldsChanged?.call(UnmodifiableListView(fields));
      },
      onFilters: (final filters) {
        _databaseCallbacks?.onFiltersChanged?.call(filters);
      },
    );
  }

  void _listenOnGroupChanged() {
    groupListener.start(
      onNumOfGroupsChanged: (final result) {
        result.fold(
          (final changeset) {
            if (changeset.updateGroups.isNotEmpty) {
              _groupCallbacks?.onUpdateGroup?.call(changeset.updateGroups);
            }

            if (changeset.deletedGroups.isNotEmpty) {
              _groupCallbacks?.onDeleteGroup?.call(changeset.deletedGroups);
            }

            for (final insertedGroup in changeset.insertedGroups) {
              _groupCallbacks?.onInsertGroup?.call(insertedGroup);
            }
          },
          (final r) => Log.error(r),
        );
      },
      onGroupByNewField: (final result) {
        result.fold(
          (final groups) {
            _groupCallbacks?.onGroupByField?.call(groups);
          },
          (final r) => Log.error(r),
        );
      },
    );
  }

  void _listenOnLayoutChanged() {
    layoutListener.start(
      onLayoutChanged: (final result) {
        result.fold(
          (final l) {
            _layoutCallbacks?.onLayoutChanged(l);
          },
          (final r) => Log.error(r),
        );
      },
    );
  }

  void _listenOnCalendarLayoutChanged() {
    calendarLayoutListener.start(
      onCalendarLayoutChanged: (final result) {
        result.fold(
          (final l) {
            _calendarLayoutCallbacks?.onCalendarLayoutChanged(l);
          },
          (final r) => Log.error(r),
        );
      },
    );
  }
}

class RowDataBuilder {
  final _cellDataByFieldId = <String, String>{};

  void insertText(final FieldInfo fieldInfo, final String text) {
    assert(fieldInfo.fieldType == FieldType.RichText);
    _cellDataByFieldId[fieldInfo.field.id] = text;
  }

  void insertNumber(final FieldInfo fieldInfo, final int num) {
    assert(fieldInfo.fieldType == FieldType.Number);
    _cellDataByFieldId[fieldInfo.field.id] = num.toString();
  }

  /// The date should use the UTC timezone. Becuase the backend uses UTC timezone to format the time string.
  void insertDate(final FieldInfo fieldInfo, final DateTime date) {
    assert(fieldInfo.fieldType == FieldType.DateTime);
    final timestamp = (date.toUtc().millisecondsSinceEpoch ~/ 1000);
    _cellDataByFieldId[fieldInfo.field.id] = timestamp.toString();
  }

  Map<String, String> build() {
    return _cellDataByFieldId;
  }
}

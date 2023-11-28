import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/view/view_cache.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/board_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'database_view_service.dart';
import 'defines.dart';
import 'field/field_info.dart';
import 'layout/layout_service.dart';
import 'layout/layout_setting_listener.dart';
import 'row/row_cache.dart';
import 'group/group_listener.dart';
import 'row/row_service.dart';

typedef OnGroupConfigurationChanged = void Function(List<GroupSettingPB>);
typedef OnGroupByField = void Function(List<GroupPB>);
typedef OnUpdateGroup = void Function(List<GroupPB>);
typedef OnDeleteGroup = void Function(List<String>);
typedef OnInsertGroup = void Function(InsertedGroupPB);

class GroupCallbacks {
  final OnGroupConfigurationChanged? onGroupConfigurationChanged;
  final OnGroupByField? onGroupByField;
  final OnUpdateGroup? onUpdateGroup;
  final OnDeleteGroup? onDeleteGroup;
  final OnInsertGroup? onInsertGroup;

  GroupCallbacks({
    this.onGroupConfigurationChanged,
    this.onGroupByField,
    this.onUpdateGroup,
    this.onDeleteGroup,
    this.onInsertGroup,
  });
}

class DatabaseLayoutSettingCallbacks {
  final void Function(DatabaseLayoutSettingPB) onLayoutSettingsChanged;

  DatabaseLayoutSettingCallbacks({
    required this.onLayoutSettingsChanged,
  });
}

class DatabaseCallbacks {
  OnDatabaseChanged? onDatabaseChanged;
  OnFieldsChanged? onFieldsChanged;
  OnFiltersChanged? onFiltersChanged;
  OnSortsChanged? onSortsChanged;
  OnNumOfRowsChanged? onNumOfRowsChanged;
  OnRowsDeleted? onRowsDeleted;
  OnRowsUpdated? onRowsUpdated;
  OnRowsCreated? onRowsCreated;

  DatabaseCallbacks({
    this.onDatabaseChanged,
    this.onNumOfRowsChanged,
    this.onFieldsChanged,
    this.onFiltersChanged,
    this.onSortsChanged,
    this.onRowsUpdated,
    this.onRowsDeleted,
    this.onRowsCreated,
  });
}

class DatabaseController {
  final String viewId;
  final DatabaseViewBackendService _databaseViewBackendSvc;
  final FieldController fieldController;
  DatabaseLayoutPB databaseLayout;
  DatabaseLayoutSettingPB? databaseLayoutSetting;
  late DatabaseViewCache _viewCache;

  // Callbacks
  final List<DatabaseCallbacks> _databaseCallbacks = [];
  final List<GroupCallbacks> _groupCallbacks = [];
  final List<DatabaseLayoutSettingCallbacks> _layoutCallbacks = [];

  // Getters
  RowCache get rowCache => _viewCache.rowCache;

  // Listener
  final DatabaseGroupListener _groupListener;
  final DatabaseLayoutSettingListener _layoutListener;

  final ValueNotifier<bool> _isLoading = ValueNotifier(true);

  DatabaseController({required ViewPB view})
      : viewId = view.id,
        _databaseViewBackendSvc = DatabaseViewBackendService(viewId: view.id),
        fieldController = FieldController(viewId: view.id),
        _groupListener = DatabaseGroupListener(view.id),
        databaseLayout = databaseLayoutFromViewLayout(view.layout),
        _layoutListener = DatabaseLayoutSettingListener(view.id) {
    _viewCache = DatabaseViewCache(
      viewId: viewId,
      fieldController: fieldController,
    );
    _listenOnRowsChanged();
    _listenOnFieldsChanged();
    _listenOnGroupChanged();
    _listenOnLayoutChanged();
  }

  void setIsLoading(bool isLoading) {
    _isLoading.value = isLoading;
  }

  ValueNotifier<bool> get isLoading => _isLoading;

  void addListener({
    DatabaseCallbacks? onDatabaseChanged,
    DatabaseLayoutSettingCallbacks? onLayoutSettingsChanged,
    GroupCallbacks? onGroupChanged,
  }) {
    if (onLayoutSettingsChanged != null) {
      _layoutCallbacks.add(onLayoutSettingsChanged);
    }

    if (onDatabaseChanged != null) {
      _databaseCallbacks.add(onDatabaseChanged);
    }

    if (onGroupChanged != null) {
      _groupCallbacks.add(onGroupChanged);
    }
  }

  Future<Either<Unit, FlowyError>> open() async {
    return _databaseViewBackendSvc.openDatabase().then((result) {
      return result.fold(
        (DatabasePB database) async {
          databaseLayout = database.layoutType;

          // Load the actual database field data.
          final fieldsOrFail = await fieldController.loadFields(
            fieldIds: database.fields,
          );
          return fieldsOrFail.fold(
            (fields) {
              // Notify the database is changed after the fields are loaded.
              // The database won't can't be used until the fields are loaded.
              for (final callback in _databaseCallbacks) {
                callback.onDatabaseChanged?.call(database);
              }
              _viewCache.rowCache.setInitialRows(database.rows);
              return Future(() async {
                await _loadGroups();
                await _loadLayoutSetting();
                return left(fields);
              });
            },
            (err) {
              Log.error(err);
              return right(err);
            },
          );
        },
        (err) => right(err),
      );
    });
  }

  Future<Either<RowMetaPB, FlowyError>> createRow({
    RowId? startRowId,
    String? groupId,
    bool fromBeginning = false,
    void Function(RowDataBuilder builder)? withCells,
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
      fromBeginning: fromBeginning,
    );
  }

  Future<Either<Unit, FlowyError>> moveGroupRow({
    required RowMetaPB fromRow,
    required String fromGroupId,
    required String toGroupId,
    RowMetaPB? toRow,
  }) {
    return _databaseViewBackendSvc.moveGroupRow(
      fromRowId: fromRow.id,
      fromGroupId: fromGroupId,
      toGroupId: toGroupId,
      toRowId: toRow?.id,
    );
  }

  Future<Either<Unit, FlowyError>> moveRow({
    required String fromRowId,
    required String toRowId,
  }) {
    return _databaseViewBackendSvc.moveRow(
      fromRowId: fromRowId,
      toRowId: toRowId,
    );
  }

  Future<Either<Unit, FlowyError>> moveGroup({
    required String fromGroupId,
    required String toGroupId,
  }) {
    return _databaseViewBackendSvc.moveGroup(
      fromGroupId: fromGroupId,
      toGroupId: toGroupId,
    );
  }

  Future<void> updateLayoutSetting({
    BoardLayoutSettingPB? boardLayoutSetting,
    CalendarLayoutSettingPB? calendarLayoutSetting,
  }) async {
    await _databaseViewBackendSvc
        .updateLayoutSetting(
      boardLayoutSetting: boardLayoutSetting,
      calendarLayoutSetting: calendarLayoutSetting,
      layoutType: databaseLayout,
    )
        .then((result) {
      result.fold((l) => null, (r) => Log.error(r));
    });
  }

  Future<void> dispose() async {
    await _databaseViewBackendSvc.closeView();
    await fieldController.dispose();
    await _groupListener.stop();
    await _viewCache.dispose();
    _databaseCallbacks.clear();
    _groupCallbacks.clear();
    _layoutCallbacks.clear();
  }

  Future<void> _loadGroups() async {
    final groupsResult = await _databaseViewBackendSvc.loadGroups();
    groupsResult.fold(
      (groups) {
        for (final callback in _groupCallbacks) {
          callback.onGroupByField?.call(groups.items);
        }
      },
      (err) => Log.error(err),
    );
  }

  Future<void> _loadLayoutSetting() async {
    _databaseViewBackendSvc.getLayoutSetting(databaseLayout).then((result) {
      result.fold(
        (newDatabaseLayoutSetting) {
          databaseLayoutSetting = newDatabaseLayoutSetting;

          for (final callback in _layoutCallbacks) {
            callback.onLayoutSettingsChanged(newDatabaseLayoutSetting);
          }
        },
        (r) => Log.error(r),
      );
    });
  }

  void _listenOnRowsChanged() {
    final callbacks = DatabaseViewCallbacks(
      onNumOfRowsChanged: (rows, rowByRowId, reason) {
        for (final callback in _databaseCallbacks) {
          callback.onNumOfRowsChanged?.call(rows, rowByRowId, reason);
        }
      },
      onRowsDeleted: (ids) {
        for (final callback in _databaseCallbacks) {
          callback.onRowsDeleted?.call(ids);
        }
      },
      onRowsUpdated: (ids, reason) {
        for (final callback in _databaseCallbacks) {
          callback.onRowsUpdated?.call(ids, reason);
        }
      },
      onRowsCreated: (ids) {
        for (final callback in _databaseCallbacks) {
          callback.onRowsCreated?.call(ids);
        }
      },
    );
    _viewCache.addListener(callbacks);
  }

  void _listenOnFieldsChanged() {
    fieldController.addListener(
      onReceiveFields: (fields) {
        for (final callback in _databaseCallbacks) {
          callback.onFieldsChanged?.call(UnmodifiableListView(fields));
        }
      },
      onSorts: (sorts) {
        for (final callback in _databaseCallbacks) {
          callback.onSortsChanged?.call(sorts);
        }
      },
      onFilters: (filters) {
        for (final callback in _databaseCallbacks) {
          callback.onFiltersChanged?.call(filters);
        }
      },
    );
  }

  void _listenOnGroupChanged() {
    _groupListener.start(
      onNumOfGroupsChanged: (result) {
        result.fold(
          (changeset) {
            if (changeset.updateGroups.isNotEmpty) {
              for (final callback in _groupCallbacks) {
                callback.onUpdateGroup?.call(changeset.updateGroups);
              }
            }

            if (changeset.deletedGroups.isNotEmpty) {
              for (final callback in _groupCallbacks) {
                callback.onDeleteGroup?.call(changeset.deletedGroups);
              }
            }

            for (final insertedGroup in changeset.insertedGroups) {
              for (final callback in _groupCallbacks) {
                callback.onInsertGroup?.call(insertedGroup);
              }
            }
          },
          (r) => Log.error(r),
        );
      },
      onGroupByNewField: (result) {
        result.fold(
          (groups) {
            for (final callback in _groupCallbacks) {
              callback.onGroupByField?.call(groups);
            }
          },
          (r) => Log.error(r),
        );
      },
    );
  }

  void _listenOnLayoutChanged() {
    _layoutListener.start(
      onLayoutChanged: (result) {
        result.fold(
          (newLayout) {
            databaseLayoutSetting = newLayout;
            databaseLayoutSetting?.freeze();

            for (final callback in _layoutCallbacks) {
              callback.onLayoutSettingsChanged(newLayout);
            }
          },
          (r) => Log.error(r),
        );
      },
    );
  }
}

class RowDataBuilder {
  final _cellDataByFieldId = <String, String>{};

  void insertText(FieldInfo fieldInfo, String text) {
    assert(fieldInfo.fieldType == FieldType.RichText);
    _cellDataByFieldId[fieldInfo.field.id] = text;
  }

  void insertNumber(FieldInfo fieldInfo, int num) {
    assert(fieldInfo.fieldType == FieldType.Number);
    _cellDataByFieldId[fieldInfo.field.id] = num.toString();
  }

  void insertDate(FieldInfo fieldInfo, DateTime date) {
    assert(FieldType.DateTime == fieldInfo.fieldType);
    final timestamp = date.millisecondsSinceEpoch ~/ 1000;
    _cellDataByFieldId[fieldInfo.field.id] = timestamp.toString();
  }

  Map<String, String> build() {
    return _cellDataByFieldId;
  }
}

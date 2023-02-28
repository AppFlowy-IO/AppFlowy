import 'dart:async';
import 'dart:collection';

import 'package:appflowy/plugins/database_view/application/database_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/view/view_cache.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'package:dartz/dartz.dart';

import 'calendar_listener.dart';

typedef OnFieldsChanged = void Function(UnmodifiableListView<FieldInfo>);
typedef OnDatabaseChanged = void Function(DatabasePB);
typedef OnSettingsChanged = void Function(CalendarSettingsPB);
typedef OnArrangeWithNewField = void Function(FieldPB);

typedef OnRowsChanged = void Function(List<RowInfo>, RowsChangedReason);
typedef OnError = void Function(FlowyError);

class CalendarDataController {
  final String databaseId;
  final DatabaseBackendService _databaseBackendSvc;
  final FieldController fieldController;
  final CalendarListener _listener;
  late DatabaseViewCache _viewCache;

  OnFieldsChanged? _onFieldsChanged;
  OnDatabaseChanged? _onDatabaseChanged;
  OnRowsChanged? _onRowsChanged;
  OnSettingsChanged? _onSettingsChanged;
  OnArrangeWithNewField? _onArrangeWithNewField;
  OnError? _onError;

  List<RowInfo> get rowInfos => _viewCache.rowInfos;
  RowCache get rowCache => _viewCache.rowCache;

  CalendarDataController({required ViewPB view})
      : databaseId = view.id,
        _listener = CalendarListener(view.id),
        _databaseBackendSvc = DatabaseBackendService(viewId: view.id),
        fieldController = FieldController(viewId: view.id) {
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
    OnRowsChanged? onRowsChanged,
    required OnSettingsChanged? onSettingsChanged,
    required OnArrangeWithNewField? onArrangeWithNewField,
    required OnError? onError,
  }) {
    _onDatabaseChanged = onDatabaseChanged;
    _onFieldsChanged = onFieldsChanged;
    _onRowsChanged = onRowsChanged;
    _onSettingsChanged = onSettingsChanged;
    _onArrangeWithNewField = onArrangeWithNewField;
    _onError = onError;

    fieldController.addListener(onReceiveFields: (fields) {
      _onFieldsChanged?.call(UnmodifiableListView(fields));
    });

    _listener.start(
      onCalendarSettingsChanged: (result) {
        result.fold(
          (settings) => _onSettingsChanged?.call(settings),
          (e) => _onError?.call(e),
        );
      },
      onArrangeWithNewField: (result) {
        result.fold(
          (settings) => _onArrangeWithNewField?.call(settings),
          (e) => _onError?.call(e),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> openDatabase() async {
    final result = await _databaseBackendSvc.openGrid();
    return result.fold(
      (database) async {
        _onDatabaseChanged?.call(database);
        return fieldController
            .loadFields(fieldIds: database.fields)
            .then((result) {
          return result.fold(
            (l) => Future(() async {
              _viewCache.rowCache.initializeRows(database.rows);
              return left(l);
            }),
            (err) => right(err),
          );
        });
      },
      (err) => right(err),
    );
  }

  Future<void> dispose() async {
    await _viewCache.dispose();
    await _databaseBackendSvc.closeView();
    await fieldController.dispose();
  }
}

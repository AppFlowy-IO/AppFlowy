import 'package:appflowy/plugins/database_view/application/database_view_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/setting/setting_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'field_listener.dart';

class _DatabaseFieldNotifier extends ChangeNotifier {
  List<FieldPB> _fields = [];

  set fields(List<FieldPB> fields) {
    _fields = fields;
    notifyListeners();
  }

  UnmodifiableListView<FieldPB> get fields => UnmodifiableListView(_fields);
}

typedef OnReceiveUpdateFields = void Function(List<FieldPB>);
typedef OnReceiveFields = void Function(List<FieldPB>);
typedef OnReceiveFieldSettings = void Function(List<FieldPB>);

class FieldController {
  final String viewId;

  // Listeners
  final FieldsListener _fieldListener;
  final DatabaseSettingListener _settingListener;

  // FFI services
  final DatabaseViewBackendService _databaseViewBackendSvc;

  bool _isDisposed = false;

  // Field callbacks
  final Map<OnReceiveFields, VoidCallback> _fieldCallbacks = {};
  final _DatabaseFieldNotifier _fieldNotifier = _DatabaseFieldNotifier();

  // Field updated callbacks
  final Map<OnReceiveUpdateFields, void Function(List<FieldPB>)>
      _updatedFieldCallbacks = {};

  // Getters
  List<FieldPB> get fields => [..._fieldNotifier.fields];

  FieldPB? getField(String fieldId, [FieldType? fieldType]) {
    return _fieldNotifier.fields.firstWhereOrNull(
      (field) =>
          field.id == fieldId &&
          (fieldType == null || field.fieldType == fieldType),
    );
  }

  FieldController({required this.viewId})
      : _fieldListener = FieldsListener(viewId: viewId),
        _settingListener = DatabaseSettingListener(viewId: viewId),
        _databaseViewBackendSvc = DatabaseViewBackendService(viewId: viewId) {
    _listenOnFieldChanges();
  }

  /// Listen for field changes in the backend.
  void _listenOnFieldChanges() {
    void insertFields(List<IndexFieldPB> insertedFields, List<FieldPB> fields) {
      if (insertedFields.isEmpty) {
        return;
      }
      for (final indexField in insertedFields) {
        if (indexField.index < fields.length) {
          fields.insert(indexField.index, indexField.field_1);
        } else {
          fields.add(indexField.field_1);
        }
      }
    }

    void updateFields(
      List<FieldPB> fieldUpdates,
      List<FieldPB> updatedFields,
      List<FieldPB> fields,
    ) {
      if (fieldUpdates.isEmpty) {
        return;
      }

      for (final fieldUpdate in fieldUpdates) {
        final fieldIndex =
            fields.indexWhere((field) => field.id == fieldUpdate.id);
        if (fieldIndex == -1) {
          continue;
        }
        fields.removeAt(fieldIndex);
        fields.insert(fieldIndex, fieldUpdate);
        updatedFields.add(fieldUpdate);
      }
    }

    void deleteFields(List<FieldIdPB> deletedFields, List<FieldPB> fields) {
      if (deletedFields.isEmpty) {
        return;
      }
      final deletedFieldIds = deletedFields.map((e) => e.fieldId);
      fields.retainWhere((field) => !deletedFieldIds.contains(field.id));
    }

    // Listen on field's changes
    _fieldListener.start(
      onFieldsUpdated: (result) async {
        result.fold(
          (changeset) async {
            if (_isDisposed) {
              return;
            }
            final List<FieldPB> updatedFields = [];
            final List<FieldPB> newFields = fields;
            deleteFields(changeset.deletedFields, newFields);
            insertFields(changeset.insertedFields, newFields);
            updateFields(changeset.updatedFields, updatedFields, newFields);

            for (final listener in _updatedFieldCallbacks.values) {
              listener(updatedFields);
            }
            _fieldNotifier.fields = newFields;
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  /// Load all the fields. This is required when opening the database
  Future<Either<Unit, FlowyError>> loadFields({
    required List<FieldIdPB> fieldIds,
  }) async {
    final result = await _databaseViewBackendSvc.getFields(fieldIds: fieldIds);
    return Future(
      () => result.fold(
        (fields) async {
          if (_isDisposed) {
            return left(unit);
          }
          _fieldNotifier.fields = fields;
          return left(unit);
        },
        (err) => right(err),
      ),
    );
  }

  void addListener({
    OnReceiveFields? onReceiveFields,
    OnReceiveUpdateFields? onFieldsChanged,
    bool Function()? listenWhen,
  }) {
    if (onFieldsChanged != null) {
      callback(List<FieldPB> updateFields) {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onFieldsChanged(updateFields);
      }

      _updatedFieldCallbacks[onFieldsChanged] = callback;
    }

    if (onReceiveFields != null) {
      callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onReceiveFields(fields);
      }

      _fieldCallbacks[onReceiveFields] = callback;
      _fieldNotifier.addListener(callback);
    }
  }

  void removeListener({
    OnReceiveFields? onFieldsListener,
    OnReceiveUpdateFields? onChangesetListener,
  }) {
    if (onFieldsListener != null) {
      final callback = _fieldCallbacks.remove(onFieldsListener);
      if (callback != null) {
        _fieldNotifier.removeListener(callback);
      }
    }
  }

  /// Stop listeners, dispose notifiers and clear listener callbacks
  Future<void> dispose() async {
    if (_isDisposed) {
      Log.warn('FieldController is already disposed');
      return;
    }
    _isDisposed = true;
    await _fieldListener.stop();
    await _settingListener.stop();

    for (final callback in _fieldCallbacks.values) {
      _fieldNotifier.removeListener(callback);
    }
    _fieldNotifier.dispose();
  }
}

class RowCacheDependenciesImpl extends RowFieldsDelegate with RowLifeCycle {
  final FieldController _fieldController;
  OnReceiveFields? _onFieldFn;
  RowCacheDependenciesImpl(FieldController cache) : _fieldController = cache;

  @override
  UnmodifiableListView<FieldPB> get fields =>
      UnmodifiableListView(_fieldController.fields);

  @override
  void onFieldsChanged(void Function(List<FieldPB>) callback) {
    if (_onFieldFn != null) {
      _fieldController.removeListener(onFieldsListener: _onFieldFn!);
    }

    _onFieldFn = (fields) => callback(fields);
    _fieldController.addListener(onReceiveFields: _onFieldFn);
  }

  @override
  void onRowDisposed() {
    if (_onFieldFn != null) {
      _fieldController.removeListener(onFieldsListener: _onFieldFn!);
      _onFieldFn = null;
    }
  }
}

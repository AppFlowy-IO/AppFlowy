import 'package:appflowy/plugins/database_view/application/database_view_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/setting/setting_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:protobuf/protobuf.dart';

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
    void insertFields(List<IndexFieldPB> insertedFields) {
      if (insertedFields.isEmpty) {
        return;
      }
      final newFields = fields;
      for (final indexField in insertedFields) {
        if (indexField.index < newFields.length) {
          newFields.insert(indexField.index, indexField.field_1);
        } else {
          newFields.add(indexField.field_1);
        }
      }

      _fieldNotifier.fields = newFields;
    }

    List<FieldPB> updateFields(List<FieldUpdateNotificationPB> fieldUpdates) {
      if (fieldUpdates.isEmpty) {
        return [];
      }

      final newFields = fields;
      final updatedFields = <FieldPB>[];
      for (final fieldUpdate in fieldUpdates) {
        final fieldIndex =
            newFields.indexWhere((field) => field.id == fieldUpdate.fieldId);
        if (fieldIndex == -1) {
          continue;
        }
        newFields[fieldIndex].freeze();
        final newField = newFields[fieldIndex].rebuild((field) {
          if (fieldUpdate.hasName()) {
            field.name = fieldUpdate.name;
          }
          if (fieldUpdate.hasFieldType()) {
            field.fieldType = fieldUpdate.fieldType;
          }
          if (fieldUpdate.hasWidth()) {
            field.width = fieldUpdate.width;
          }
          if (fieldUpdate.hasTypeOption()) {
            field.typeOptionData = fieldUpdate.typeOption;
          }
          if (fieldUpdate.hasHasSort()) {
            field.hasSort = fieldUpdate.hasSort;
          }
          if (fieldUpdate.hasHasFilter()) {
            field.hasFilter = fieldUpdate.hasFilter;
          }
          if (fieldUpdate.hasVisibility()) {
            field.visibility = fieldUpdate.visibility;
          }
        });
        final newIndex =
            fieldUpdate.hasIndex() ? fieldUpdate.index : fieldIndex;
        newFields.removeAt(fieldIndex);
        newFields.insert(newIndex, newField);

        updatedFields.add(newField);
      }

      _fieldNotifier.fields = newFields;
      return updatedFields;
    }

    void deleteFields(List<FieldIdPB> deletedFields) {
      if (deletedFields.isEmpty) {
        return;
      }
      final List<FieldPB> newFields = fields;
      final Map<String, FieldIdPB> deletedFieldMap = {
        for (final field in deletedFields) field.fieldId: field
      };

      newFields.retainWhere((field) => (deletedFieldMap[field.id] == null));
      _fieldNotifier.fields = newFields;
    }

    // Listen on field's changes
    _fieldListener.start(
      onFieldsInserted: (result) async {
        result.fold(
          (changeset) async {
            if (_isDisposed) {
              return;
            }
            insertFields(changeset);
          },
          (err) => Log.error(err),
        );
      },
      onFieldsUpdated: (result) async {
        result.fold(
          (changeset) async {
            if (_isDisposed) {
              return;
            }
            final updatedFields = updateFields(changeset);
            for (final listener in _updatedFieldCallbacks.values) {
              listener(updatedFields);
            }
          },
          (err) => Log.error(err),
        );
      },
      onFieldsDeleted: (result) async {
        result.fold(
          (changeset) async {
            if (_isDisposed) {
              return;
            }
            deleteFields(changeset.items);
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  // /// Updates sort, filter, group and field info from `DatabaseViewSettingPB`
  // void _updateSetting(DatabaseViewSettingPB setting) {
  //   _groupConfigurationByFieldId.clear();
  //   for (final configuration in setting.groupSettings.items) {
  //     _groupConfigurationByFieldId[configuration.fieldId] = configuration;
  //   }

  //   _filterNotifier?.filters = _filterInfoListFromPBs(setting.filters.items);

  //   _sortNotifier?.sorts = _sortInfoListFromPBs(setting.sorts.items);

  //   _fieldSettings.clear();
  //   _fieldSettings.addAll(setting.fieldSettings.items);

  //   _updateFieldInfos();
  // }

  /// Attach sort, filter, group information and field settings to `FieldPB`
  // void _updateFieldInfos() {
  //   final List<FieldPB> newFieldInfos = [];
  //   for (final field in _fieldNotifier.fields) {
  //     newFieldInfos.add(
  //       field.copyWith(
  //         isGroupField: _groupConfigurationByFieldId[field.id] != null,
  //       ),
  //     );
  //   }

  //   _fieldNotifier.fields = newFieldInfos;
  // }

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

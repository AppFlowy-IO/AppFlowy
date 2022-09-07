import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/field/grid_listener.dart';
import 'package:app_flowy/plugins/grid/application/grid_service.dart';
import 'package:app_flowy/plugins/grid/application/setting/setting_listener.dart';
import 'package:app_flowy/plugins/grid/application/setting/setting_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/group.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/setting_entities.pb.dart';
import 'package:flutter/foundation.dart';
import '../row/row_cache.dart';

class _GridFieldNotifier extends ChangeNotifier {
  List<GridFieldContext> _fieldContexts = [];

  set fieldContexts(List<GridFieldContext> fieldContexts) {
    _fieldContexts = fieldContexts;
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  List<GridFieldContext> get fieldContexts => _fieldContexts;
}

typedef OnChangeset = void Function(FieldChangesetPB);
typedef OnReceiveFields = void Function(List<GridFieldContext>);

class GridFieldController {
  final String gridId;
  final GridFieldsListener _fieldListener;
  final SettingListener _settingListener;
  final Map<OnReceiveFields, VoidCallback> _fieldCallbackMap = {};
  final Map<OnChangeset, OnChangeset> _changesetCallbackMap = {};
  final GridFFIService _gridFFIService;
  final SettingFFIService _settingFFIService;

  _GridFieldNotifier? _fieldNotifier = _GridFieldNotifier();
  final Map<String, GridGroupConfigurationPB> _configurationByFieldId = {};

  List<GridFieldContext> get fieldContexts =>
      [..._fieldNotifier?.fieldContexts ?? []];

  GridFieldController({required this.gridId})
      : _fieldListener = GridFieldsListener(gridId: gridId),
        _gridFFIService = GridFFIService(gridId: gridId),
        _settingFFIService = SettingFFIService(viewId: gridId),
        _settingListener = SettingListener(gridId: gridId) {
    //Listen on field's changes
    _fieldListener.start(onFieldsChanged: (result) {
      result.fold(
        (changeset) {
          _deleteFields(changeset.deletedFields);
          _insertFields(changeset.insertedFields);
          _updateFields(changeset.updatedFields);
          for (final listener in _changesetCallbackMap.values) {
            listener(changeset);
          }
        },
        (err) => Log.error(err),
      );
    });

    //Listen on setting changes
    _settingListener.start(onSettingUpdated: (result) {
      result.fold(
        (setting) => _updateGroupConfiguration(setting),
        (r) => Log.error(r),
      );
    });

    _settingFFIService.getSetting().then((result) {
      result.fold(
        (setting) => _updateGroupConfiguration(setting),
        (err) => Log.error(err),
      );
    });
  }

  GridFieldContext? getField(String fieldId) {
    final fields = _fieldNotifier?.fieldContexts
        .where(
          (element) => element.id == fieldId,
        )
        .toList();
    if (fields?.isEmpty ?? true) {
      return null;
    }
    return fields!.first;
  }

  void _updateGroupConfiguration(GridSettingPB setting) {
    _configurationByFieldId.clear();
    for (final configuration in setting.groupConfigurations.items) {
      _configurationByFieldId[configuration.fieldId] = configuration;
    }
    _updateFieldContexts();
  }

  void _updateFieldContexts() {
    if (_fieldNotifier != null) {
      for (var field in _fieldNotifier!.fieldContexts) {
        if (_configurationByFieldId[field.id] != null) {
          field._isGroupField = true;
        } else {
          field._isGroupField = false;
        }
      }
      _fieldNotifier?.notify();
    }
  }

  Future<void> dispose() async {
    await _fieldListener.stop();
    _fieldNotifier?.dispose();
    _fieldNotifier = null;
  }

  Future<Either<Unit, FlowyError>> loadFields(
      {required List<FieldIdPB> fieldIds}) async {
    final result = await _gridFFIService.getFields(fieldIds: fieldIds);
    return Future(
      () => result.fold(
        (newFields) {
          _fieldNotifier?.fieldContexts = newFields.items
              .map((field) => GridFieldContext(field: field))
              .toList();
          _updateFieldContexts();
          return left(unit);
        },
        (err) => right(err),
      ),
    );
  }

  void addListener({
    OnReceiveFields? onFields,
    OnChangeset? onChangeset,
    bool Function()? listenWhen,
  }) {
    if (onChangeset != null) {
      callback(c) {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onChangeset(c);
      }

      _changesetCallbackMap[onChangeset] = callback;
    }

    if (onFields != null) {
      callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onFields(fieldContexts);
      }

      _fieldCallbackMap[onFields] = callback;
      _fieldNotifier?.addListener(callback);
    }
  }

  void removeListener({
    OnReceiveFields? onFieldsListener,
    OnChangeset? onChangesetListener,
  }) {
    if (onFieldsListener != null) {
      final callback = _fieldCallbackMap.remove(onFieldsListener);
      if (callback != null) {
        _fieldNotifier?.removeListener(callback);
      }
    }

    if (onChangesetListener != null) {
      _changesetCallbackMap.remove(onChangesetListener);
    }
  }

  void _deleteFields(List<FieldIdPB> deletedFields) {
    if (deletedFields.isEmpty) {
      return;
    }
    final List<GridFieldContext> newFields = fieldContexts;
    final Map<String, FieldIdPB> deletedFieldMap = {
      for (var fieldOrder in deletedFields) fieldOrder.fieldId: fieldOrder
    };

    newFields.retainWhere((field) => (deletedFieldMap[field.id] == null));
    _fieldNotifier?.fieldContexts = newFields;
  }

  void _insertFields(List<IndexFieldPB> insertedFields) {
    if (insertedFields.isEmpty) {
      return;
    }
    final List<GridFieldContext> newFields = fieldContexts;
    for (final indexField in insertedFields) {
      final gridField = GridFieldContext(field: indexField.field_1);
      if (newFields.length > indexField.index) {
        newFields.insert(indexField.index, gridField);
      } else {
        newFields.add(gridField);
      }
    }
    _fieldNotifier?.fieldContexts = newFields;
  }

  void _updateFields(List<FieldPB> updatedFields) {
    if (updatedFields.isEmpty) {
      return;
    }
    final List<GridFieldContext> newFields = fieldContexts;
    for (final updatedField in updatedFields) {
      final index =
          newFields.indexWhere((field) => field.id == updatedField.id);
      if (index != -1) {
        newFields.removeAt(index);
        final gridField = GridFieldContext(field: updatedField);
        newFields.insert(index, gridField);
      }
    }
    _fieldNotifier?.fieldContexts = newFields;
  }
}

class GridRowFieldNotifierImpl extends IGridRowFieldNotifier {
  final GridFieldController _cache;
  OnChangeset? _onChangesetFn;
  OnReceiveFields? _onFieldFn;
  GridRowFieldNotifierImpl(GridFieldController cache) : _cache = cache;

  @override
  UnmodifiableListView<GridFieldContext> get fields =>
      UnmodifiableListView(_cache.fieldContexts);

  @override
  void onRowFieldsChanged(VoidCallback callback) {
    _onFieldFn = (_) => callback();
    _cache.addListener(onFields: _onFieldFn);
  }

  @override
  void onRowFieldChanged(void Function(FieldPB) callback) {
    _onChangesetFn = (FieldChangesetPB changeset) {
      for (final updatedField in changeset.updatedFields) {
        callback(updatedField);
      }
    };

    _cache.addListener(onChangeset: _onChangesetFn);
  }

  @override
  void onRowDispose() {
    if (_onFieldFn != null) {
      _cache.removeListener(onFieldsListener: _onFieldFn!);
      _onFieldFn = null;
    }

    if (_onChangesetFn != null) {
      _cache.removeListener(onChangesetListener: _onChangesetFn!);
      _onChangesetFn = null;
    }
  }
}

class GridFieldContext {
  final FieldPB _field;
  bool _isGroupField = false;

  String get id => _field.id;

  FieldType get fieldType => _field.fieldType;

  bool get visibility => _field.visibility;

  double get width => _field.width.toDouble();

  bool get isPrimary => _field.isPrimary;

  String get name => _field.name;

  FieldPB get field => _field;

  bool get isGroupField => _isGroupField;

  bool get canGroup {
    switch (_field.fieldType) {
      case FieldType.Checkbox:
        return true;
      case FieldType.DateTime:
        return false;
      case FieldType.MultiSelect:
        return true;
      case FieldType.Number:
        return false;
      case FieldType.RichText:
        return false;
      case FieldType.SingleSelect:
        return true;
      case FieldType.URL:
        return false;
    }

    return false;
  }

  GridFieldContext({required FieldPB field}) : _field = field;
}

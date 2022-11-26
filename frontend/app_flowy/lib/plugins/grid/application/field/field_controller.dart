import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/field/grid_listener.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_listener.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_service.dart';
import 'package:app_flowy/plugins/grid/application/grid_service.dart';
import 'package:app_flowy/plugins/grid/application/setting/setting_listener.dart';
import 'package:app_flowy/plugins/grid/application/setting/setting_service.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/group.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/setting_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter/foundation.dart';
import '../row/row_cache.dart';

class _GridFieldNotifier extends ChangeNotifier {
  List<FieldInfo> _fieldInfos = [];

  set fieldInfos(List<FieldInfo> fieldInfos) {
    _fieldInfos = fieldInfos;
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  List<FieldInfo> get fieldInfos => _fieldInfos;
}

class _GridFilterNotifier extends ChangeNotifier {
  List<FilterInfo> _filters = [];

  set filters(List<FilterInfo> filters) {
    _filters = filters;
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  List<FilterInfo> get filters => _filters;
}

typedef OnReceiveUpdateFields = void Function(List<FieldInfo>);
typedef OnReceiveFields = void Function(List<FieldInfo>);
typedef OnReceiveFilters = void Function(List<FilterInfo>);

class GridFieldController {
  final String gridId;
  // Listeners
  final GridFieldsListener _fieldListener;
  final SettingListener _settingListener;
  final FiltersListener _filterListener;

  // FFI services
  final GridFFIService _gridFFIService;
  final SettingFFIService _settingFFIService;
  final FilterFFIService _filterFFIService;

  // Field callbacks
  final Map<OnReceiveFields, VoidCallback> _fieldCallbacks = {};
  _GridFieldNotifier? _fieldNotifier = _GridFieldNotifier();

  // Field updated callbacks
  final Map<OnReceiveUpdateFields, void Function(List<FieldInfo>)>
      _updatedFieldCallbacks = {};

  // Group callbacks
  final Map<String, GroupConfigurationPB> _groupConfigurationByFieldId = {};

  // Filter callbacks
  final Map<OnReceiveFilters, VoidCallback> _filterCallbacks = {};
  _GridFilterNotifier? _filterNotifier = _GridFilterNotifier();
  final Map<String, FilterPB> _filterPBByFieldId = {};

  // Getters
  List<FieldInfo> get fieldInfos => [..._fieldNotifier?.fieldInfos ?? []];
  List<FilterInfo> get filterInfos => [..._filterNotifier?.filters ?? []];
  FieldInfo? getField(String fieldId) {
    final fields = _fieldNotifier?.fieldInfos
            .where((element) => element.id == fieldId)
            .toList() ??
        [];
    if (fields.isEmpty) {
      return null;
    }
    assert(fields.length == 1);
    return fields.first;
  }

  FilterInfo? getFilter(String filterId) {
    final filters = _filterNotifier?.filters
            .where((element) => element.filter.id == filterId)
            .toList() ??
        [];
    if (filters.isEmpty) {
      return null;
    }
    assert(filters.length == 1);
    return filters.first;
  }

  GridFieldController({required this.gridId})
      : _fieldListener = GridFieldsListener(gridId: gridId),
        _settingListener = SettingListener(gridId: gridId),
        _filterListener = FiltersListener(viewId: gridId),
        _gridFFIService = GridFFIService(gridId: gridId),
        _filterFFIService = FilterFFIService(viewId: gridId),
        _settingFFIService = SettingFFIService(viewId: gridId) {
    //Listen on field's changes
    _listenOnFieldChanges();

    //Listen on setting changes
    _listenOnSettingChanges();

    //Listen on the fitler changes
    _listenOnFilterChanges();

    _settingFFIService.getSetting().then((result) {
      result.fold(
        (setting) => _updateSettingConfiguration(setting),
        (err) => Log.error(err),
      );
    });
  }

  void _listenOnFilterChanges() {
    //Listen on the fitler changes
    _filterListener.start(onFilterChanged: (result) {
      result.fold(
        (changeset) {
          final List<FilterInfo> filters = filterInfos;
          // Deletes the filters
          final deleteFilterIds =
              changeset.deleteFilters.map((e) => e.id).toList();
          if (deleteFilterIds.isNotEmpty) {
            filters.retainWhere(
              (element) => !deleteFilterIds.contains(element.filter.id),
            );
          }

          // Inserts the new filter if it's not exist
          for (final newFilter in changeset.insertFilters) {
            final filterIndex = filters
                .indexWhere((element) => element.filter.id == newFilter.id);
            if (filterIndex == -1) {
              final fieldInfo = _findFieldInfoForFilter(fieldInfos, newFilter);
              if (fieldInfo != null) {
                filters.add(FilterInfo(gridId, newFilter, fieldInfo));
              }
            }
          }

          for (final updatedFilter in changeset.updateFilters) {
            final filterIndex = filters.indexWhere(
              (element) => element.filter.id == updatedFilter.filterId,
            );
            // Remove the old filter
            if (filterIndex != -1) {
              filters.removeAt(filterIndex);
              _filterPBByFieldId.removeWhere(
                  (key, value) => value.id == updatedFilter.filterId);
            }

            // Insert the filter if there is a fitler and its field info is
            // not null
            if (updatedFilter.hasFilter()) {
              final fieldInfo = _findFieldInfoForFilter(
                fieldInfos,
                updatedFilter.filter,
              );

              if (fieldInfo != null) {
                // Insert the filter with the position: filterIndex, otherwise,
                // append it to the end of the list.
                final filterInfo =
                    FilterInfo(gridId, updatedFilter.filter, fieldInfo);
                if (filterIndex != -1) {
                  filters.insert(filterIndex, filterInfo);
                } else {
                  filters.add(filterInfo);
                }
                _filterPBByFieldId[fieldInfo.id] = updatedFilter.filter;
              }

              _updateFieldInfos();
            }
          }
          _filterNotifier?.filters = filters;
        },
        (err) => Log.error(err),
      );
    });
  }

  void _listenOnSettingChanges() {
    //Listen on setting changes
    _settingListener.start(onSettingUpdated: (result) {
      result.fold(
        (setting) => _updateSettingConfiguration(setting),
        (r) => Log.error(r),
      );
    });
  }

  void _listenOnFieldChanges() {
    //Listen on field's changes
    _fieldListener.start(onFieldsChanged: (result) {
      result.fold(
        (changeset) {
          _deleteFields(changeset.deletedFields);
          _insertFields(changeset.insertedFields);

          final updateFields = _updateFields(changeset.updatedFields);
          for (final listener in _updatedFieldCallbacks.values) {
            listener(updateFields);
          }
        },
        (err) => Log.error(err),
      );
    });
  }

  void _updateSettingConfiguration(GridSettingPB setting) {
    _groupConfigurationByFieldId.clear();
    for (final configuration in setting.groupConfigurations.items) {
      _groupConfigurationByFieldId[configuration.fieldId] = configuration;
    }

    for (final configuration in setting.filters.items) {
      _filterPBByFieldId[configuration.fieldId] = configuration;
    }

    _updateFieldInfos();
  }

  void _updateFieldInfos() {
    if (_fieldNotifier != null) {
      for (var field in _fieldNotifier!.fieldInfos) {
        field._isGroupField = _groupConfigurationByFieldId[field.id] != null;
        field._hasFilter = _filterPBByFieldId[field.id] != null;
      }
      _fieldNotifier?.notify();
    }
  }

  Future<void> dispose() async {
    await _fieldListener.stop();
    await _filterListener.stop();
    await _settingListener.stop();

    for (final callback in _fieldCallbacks.values) {
      _fieldNotifier?.removeListener(callback);
    }
    _fieldNotifier?.dispose();
    _fieldNotifier = null;

    for (final callback in _filterCallbacks.values) {
      _filterNotifier?.removeListener(callback);
    }
    _filterNotifier?.dispose();
    _filterNotifier = null;
  }

  Future<Either<Unit, FlowyError>> loadFields({
    required List<FieldIdPB> fieldIds,
  }) async {
    final result = await _gridFFIService.getFields(fieldIds: fieldIds);
    return Future(
      () => result.fold(
        (newFields) {
          _fieldNotifier?.fieldInfos =
              newFields.map((field) => FieldInfo(field: field)).toList();
          _loadFilters();
          _updateFieldInfos();
          return left(unit);
        },
        (err) => right(err),
      ),
    );
  }

  Future<Either<Unit, FlowyError>> _loadFilters() async {
    return _filterFFIService.getAllFilters().then((result) {
      return result.fold(
        (filterPBs) {
          final List<FilterInfo> filters = [];
          for (final filterPB in filterPBs) {
            final fieldInfo = _findFieldInfoForFilter(fieldInfos, filterPB);
            if (fieldInfo != null) {
              final filterInfo = FilterInfo(gridId, filterPB, fieldInfo);
              filters.add(filterInfo);
            }
          }

          _updateFieldInfos();
          _filterNotifier?.filters = filters;
          return left(unit);
        },
        (err) => right(err),
      );
    });
  }

  void addListener({
    OnReceiveFields? onFields,
    OnReceiveUpdateFields? onFieldsUpdated,
    OnReceiveFilters? onFilters,
    bool Function()? listenWhen,
  }) {
    if (onFieldsUpdated != null) {
      callback(List<FieldInfo> updateFields) {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onFieldsUpdated(updateFields);
      }

      _updatedFieldCallbacks[onFieldsUpdated] = callback;
    }

    if (onFields != null) {
      callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onFields(fieldInfos);
      }

      _fieldCallbacks[onFields] = callback;
      _fieldNotifier?.addListener(callback);
    }

    if (onFilters != null) {
      callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onFilters(filterInfos);
      }

      _filterCallbacks[onFilters] = callback;
      callback();
      _filterNotifier?.addListener(callback);
    }
  }

  void removeListener({
    OnReceiveFields? onFieldsListener,
    OnReceiveFilters? onFiltersListener,
    OnReceiveUpdateFields? onChangesetListener,
  }) {
    if (onFieldsListener != null) {
      final callback = _fieldCallbacks.remove(onFieldsListener);
      if (callback != null) {
        _fieldNotifier?.removeListener(callback);
      }
    }
    if (onFiltersListener != null) {
      final callback = _filterCallbacks.remove(onFiltersListener);
      if (callback != null) {
        _filterNotifier?.removeListener(callback);
      }
    }
  }

  void _deleteFields(List<FieldIdPB> deletedFields) {
    if (deletedFields.isEmpty) {
      return;
    }
    final List<FieldInfo> newFields = fieldInfos;
    final Map<String, FieldIdPB> deletedFieldMap = {
      for (var fieldOrder in deletedFields) fieldOrder.fieldId: fieldOrder
    };

    newFields.retainWhere((field) => (deletedFieldMap[field.id] == null));
    _fieldNotifier?.fieldInfos = newFields;
  }

  void _insertFields(List<IndexFieldPB> insertedFields) {
    if (insertedFields.isEmpty) {
      return;
    }
    final List<FieldInfo> newFields = fieldInfos;
    for (final indexField in insertedFields) {
      final gridField = FieldInfo(field: indexField.field_1);
      if (newFields.length > indexField.index) {
        newFields.insert(indexField.index, gridField);
      } else {
        newFields.add(gridField);
      }
    }
    _fieldNotifier?.fieldInfos = newFields;
  }

  List<FieldInfo> _updateFields(List<FieldPB> updatedFieldPBs) {
    if (updatedFieldPBs.isEmpty) {
      return [];
    }

    final List<FieldInfo> newFields = fieldInfos;
    final List<FieldInfo> updatedFields = [];
    for (final updatedFieldPB in updatedFieldPBs) {
      final index =
          newFields.indexWhere((field) => field.id == updatedFieldPB.id);
      if (index != -1) {
        newFields.removeAt(index);
        final fieldInfo = FieldInfo(field: updatedFieldPB);
        newFields.insert(index, fieldInfo);
        updatedFields.add(fieldInfo);
      }
    }

    if (updatedFields.isNotEmpty) {
      _fieldNotifier?.fieldInfos = newFields;
    }
    return updatedFields;
  }
}

class GridRowFieldNotifierImpl extends IGridRowFieldNotifier {
  final GridFieldController _cache;
  OnReceiveUpdateFields? _onChangesetFn;
  OnReceiveFields? _onFieldFn;
  GridRowFieldNotifierImpl(GridFieldController cache) : _cache = cache;

  @override
  UnmodifiableListView<FieldInfo> get fields =>
      UnmodifiableListView(_cache.fieldInfos);

  @override
  void onRowFieldsChanged(VoidCallback callback) {
    _onFieldFn = (_) => callback();
    _cache.addListener(onFields: _onFieldFn);
  }

  @override
  void onRowFieldChanged(void Function(FieldInfo) callback) {
    _onChangesetFn = (List<FieldInfo> fieldInfos) {
      for (final updatedField in fieldInfos) {
        callback(updatedField);
      }
    };

    _cache.addListener(onFieldsUpdated: _onChangesetFn);
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

FieldInfo? _findFieldInfoForFilter(
    List<FieldInfo> fieldInfos, FilterPB filter) {
  final fieldIndex = fieldInfos.indexWhere((element) {
    return element.id == filter.fieldId &&
        element.fieldType == filter.fieldType;
  });
  if (fieldIndex != -1) {
    return fieldInfos[fieldIndex];
  } else {
    return null;
  }
}

class FieldInfo {
  final FieldPB _field;
  bool _isGroupField = false;

  bool _hasFilter = false;

  String get id => _field.id;

  FieldType get fieldType => _field.fieldType;

  bool get visibility => _field.visibility;

  double get width => _field.width.toDouble();

  bool get isPrimary => _field.isPrimary;

  String get name => _field.name;

  FieldPB get field => _field;

  bool get isGroupField => _isGroupField;

  bool get hasFilter => _hasFilter;

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

  bool get canCreateFilter {
    if (hasFilter) return false;

    if (_field.fieldType != FieldType.RichText) return false;

    return true;
  }

  FieldInfo({required FieldPB field}) : _field = field;
}

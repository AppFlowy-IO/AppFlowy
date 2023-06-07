import 'dart:collection';
import 'package:appflowy_backend/protobuf/flowy-database2/filter_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:flutter/foundation.dart';
import '../../grid/presentation/widgets/filter/filter_info.dart';
import '../../grid/presentation/widgets/sort/sort_info.dart';
import '../database_view_service.dart';
import '../filter/filter_listener.dart';
import '../filter/filter_service.dart';
import '../row/row_cache.dart';
import '../setting/setting_listener.dart';
import '../setting/setting_service.dart';
import '../sort/sort_listener.dart';
import '../sort/sort_service.dart';
import 'field_listener.dart';

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

class _GridSortNotifier extends ChangeNotifier {
  List<SortInfo> _sorts = [];

  set sorts(List<SortInfo> sorts) {
    _sorts = sorts;
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  List<SortInfo> get sorts => _sorts;
}

typedef OnReceiveUpdateFields = void Function(List<FieldInfo>);
typedef OnReceiveFields = void Function(List<FieldInfo>);
typedef OnReceiveFilters = void Function(List<FilterInfo>);
typedef OnReceiveSorts = void Function(List<SortInfo>);

class FieldController {
  final String viewId;
  // Listeners
  final FieldsListener _fieldListener;
  final DatabaseSettingListener _settingListener;
  final FiltersListener _filtersListener;
  final SortsListener _sortsListener;

  // FFI services
  final DatabaseViewBackendService _databaseViewBackendSvc;
  final SettingBackendService _settingBackendSvc;
  final FilterBackendService _filterBackendSvc;
  final SortBackendService _sortBackendSvc;

  // Field callbacks
  final Map<OnReceiveFields, VoidCallback> _fieldCallbacks = {};
  _GridFieldNotifier? _fieldNotifier = _GridFieldNotifier();

  // Field updated callbacks
  final Map<OnReceiveUpdateFields, void Function(List<FieldInfo>)>
      _updatedFieldCallbacks = {};

  // Group callbacks
  final Map<String, GroupSettingPB> _groupConfigurationByFieldId = {};

  // Filter callbacks
  final Map<OnReceiveFilters, VoidCallback> _filterCallbacks = {};
  _GridFilterNotifier? _filterNotifier = _GridFilterNotifier();
  final Map<String, FilterPB> _filterPBByFieldId = {};

  // Sort callbacks
  final Map<OnReceiveSorts, VoidCallback> _sortCallbacks = {};
  _GridSortNotifier? _sortNotifier = _GridSortNotifier();
  final Map<String, SortPB> _sortPBByFieldId = {};

  // Getters
  List<FieldInfo> get fieldInfos => [..._fieldNotifier?.fieldInfos ?? []];
  List<FilterInfo> get filterInfos => [..._filterNotifier?.filters ?? []];
  List<SortInfo> get sortInfos => [..._sortNotifier?.sorts ?? []];

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

  SortInfo? getSort(String sortId) {
    final sorts = _sortNotifier?.sorts
            .where((element) => element.sortId == sortId)
            .toList() ??
        [];
    if (sorts.isEmpty) {
      return null;
    }
    assert(sorts.length == 1);
    return sorts.first;
  }

  FieldController({required this.viewId})
      : _fieldListener = FieldsListener(viewId: viewId),
        _settingListener = DatabaseSettingListener(viewId: viewId),
        _filterBackendSvc = FilterBackendService(viewId: viewId),
        _filtersListener = FiltersListener(viewId: viewId),
        _databaseViewBackendSvc = DatabaseViewBackendService(viewId: viewId),
        _sortBackendSvc = SortBackendService(viewId: viewId),
        _sortsListener = SortsListener(viewId: viewId),
        _settingBackendSvc = SettingBackendService(viewId: viewId) {
    //Listen on field's changes
    _listenOnFieldChanges();

    //Listen on setting changes
    _listenOnSettingChanges();

    //Listen on the filter changes
    _listenOnFilterChanges();

    //Listen on the sort changes
    _listenOnSortChanged();

    _settingBackendSvc.getSetting().then((result) {
      result.fold(
        (setting) => _updateSetting(setting),
        (err) => Log.error(err),
      );
    });
  }

  void _listenOnFilterChanges() {
    //Listen on the filter changes

    deleteFilterFromChangeset(
      List<FilterInfo> filters,
      FilterChangesetNotificationPB changeset,
    ) {
      final deleteFilterIds = changeset.deleteFilters.map((e) => e.id).toList();
      if (deleteFilterIds.isNotEmpty) {
        filters.retainWhere(
          (element) => !deleteFilterIds.contains(element.filter.id),
        );

        _filterPBByFieldId
            .removeWhere((key, value) => deleteFilterIds.contains(value.id));
      }
    }

    insertFilterFromChangeset(
      List<FilterInfo> filters,
      FilterChangesetNotificationPB changeset,
    ) {
      for (final newFilter in changeset.insertFilters) {
        final filterIndex =
            filters.indexWhere((element) => element.filter.id == newFilter.id);
        if (filterIndex == -1) {
          final fieldInfo = _findFieldInfo(
            fieldInfos: fieldInfos,
            fieldId: newFilter.fieldId,
            fieldType: newFilter.fieldType,
          );
          if (fieldInfo != null) {
            _filterPBByFieldId[fieldInfo.id] = newFilter;
            filters.add(FilterInfo(viewId, newFilter, fieldInfo));
          }
        }
      }
    }

    updateFilterFromChangeset(
      List<FilterInfo> filters,
      FilterChangesetNotificationPB changeset,
    ) {
      for (final updatedFilter in changeset.updateFilters) {
        final filterIndex = filters.indexWhere(
          (element) => element.filter.id == updatedFilter.filterId,
        );
        // Remove the old filter
        if (filterIndex != -1) {
          filters.removeAt(filterIndex);
          _filterPBByFieldId
              .removeWhere((key, value) => value.id == updatedFilter.filterId);
        }

        // Insert the filter if there is a filter and its field info is
        // not null
        if (updatedFilter.hasFilter()) {
          final fieldInfo = _findFieldInfo(
            fieldInfos: fieldInfos,
            fieldId: updatedFilter.filter.fieldId,
            fieldType: updatedFilter.filter.fieldType,
          );

          if (fieldInfo != null) {
            // Insert the filter with the position: filterIndex, otherwise,
            // append it to the end of the list.
            final filterInfo =
                FilterInfo(viewId, updatedFilter.filter, fieldInfo);
            if (filterIndex != -1) {
              filters.insert(filterIndex, filterInfo);
            } else {
              filters.add(filterInfo);
            }
            _filterPBByFieldId[fieldInfo.id] = updatedFilter.filter;
          }
        }
      }
    }

    _filtersListener.start(
      onFilterChanged: (result) {
        result.fold(
          (FilterChangesetNotificationPB changeset) {
            final List<FilterInfo> filters = filterInfos;
            // Deletes the filters
            deleteFilterFromChangeset(filters, changeset);

            // Inserts the new filter if it's not exist
            insertFilterFromChangeset(filters, changeset);

            updateFilterFromChangeset(filters, changeset);

            _updateFieldInfos();
            _filterNotifier?.filters = filters;
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  void _listenOnSortChanged() {
    deleteSortFromChangeset(
      List<SortInfo> newSortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      final deleteSortIds = changeset.deleteSorts.map((e) => e.id).toList();
      if (deleteSortIds.isNotEmpty) {
        newSortInfos.retainWhere(
          (element) => !deleteSortIds.contains(element.sortId),
        );

        _sortPBByFieldId
            .removeWhere((key, value) => deleteSortIds.contains(value.id));
      }
    }

    insertSortFromChangeset(
      List<SortInfo> newSortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      for (final newSortPB in changeset.insertSorts) {
        final sortIndex = newSortInfos
            .indexWhere((element) => element.sortId == newSortPB.id);
        if (sortIndex == -1) {
          final fieldInfo = _findFieldInfo(
            fieldInfos: fieldInfos,
            fieldId: newSortPB.fieldId,
            fieldType: newSortPB.fieldType,
          );

          if (fieldInfo != null) {
            _sortPBByFieldId[newSortPB.fieldId] = newSortPB;
            newSortInfos.add(SortInfo(sortPB: newSortPB, fieldInfo: fieldInfo));
          }
        }
      }
    }

    updateSortFromChangeset(
      List<SortInfo> newSortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      for (final updatedSort in changeset.updateSorts) {
        final sortIndex = newSortInfos.indexWhere(
          (element) => element.sortId == updatedSort.id,
        );
        // Remove the old filter
        if (sortIndex != -1) {
          newSortInfos.removeAt(sortIndex);
        }

        final fieldInfo = _findFieldInfo(
          fieldInfos: fieldInfos,
          fieldId: updatedSort.fieldId,
          fieldType: updatedSort.fieldType,
        );

        if (fieldInfo != null) {
          final newSortInfo = SortInfo(
            sortPB: updatedSort,
            fieldInfo: fieldInfo,
          );
          if (sortIndex != -1) {
            newSortInfos.insert(sortIndex, newSortInfo);
          } else {
            newSortInfos.add(newSortInfo);
          }
          _sortPBByFieldId[updatedSort.fieldId] = updatedSort;
        }
      }
    }

    _sortsListener.start(
      onSortChanged: (result) {
        result.fold(
          (SortChangesetNotificationPB changeset) {
            final List<SortInfo> newSortInfos = sortInfos;
            deleteSortFromChangeset(newSortInfos, changeset);
            insertSortFromChangeset(newSortInfos, changeset);
            updateSortFromChangeset(newSortInfos, changeset);

            _updateFieldInfos();
            _sortNotifier?.sorts = newSortInfos;
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  void _listenOnSettingChanges() {
    //Listen on setting changes
    _settingListener.start(
      onSettingUpdated: (result) {
        result.fold(
          (setting) => _updateSetting(setting),
          (r) => Log.error(r),
        );
      },
    );
  }

  void _listenOnFieldChanges() {
    //Listen on field's changes
    _fieldListener.start(
      onFieldsChanged: (result) {
        result.fold(
          (changeset) {
            _deleteFields(changeset.deletedFields);
            _insertFields(changeset.insertedFields);

            final updatedFields = _updateFields(changeset.updatedFields);
            for (final listener in _updatedFieldCallbacks.values) {
              listener(updatedFields);
            }
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  void _updateSetting(DatabaseViewSettingPB setting) {
    _groupConfigurationByFieldId.clear();
    for (final configuration in setting.groupSettings.items) {
      _groupConfigurationByFieldId[configuration.fieldId] = configuration;
    }

    for (final filter in setting.filters.items) {
      _filterPBByFieldId[filter.fieldId] = filter;
    }

    for (final sort in setting.sorts.items) {
      _sortPBByFieldId[sort.fieldId] = sort;
    }

    _updateFieldInfos();
  }

  void _updateFieldInfos() {
    if (_fieldNotifier != null) {
      for (final field in _fieldNotifier!.fieldInfos) {
        field._isGroupField = _groupConfigurationByFieldId[field.id] != null;
        field._hasFilter = _filterPBByFieldId[field.id] != null;
        field._hasSort = _sortPBByFieldId[field.id] != null;
      }
      _fieldNotifier?.notify();
    }
  }

  Future<void> dispose() async {
    await _fieldListener.stop();
    await _filtersListener.stop();
    await _settingListener.stop();
    await _sortsListener.stop();

    for (final callback in _fieldCallbacks.values) {
      _fieldNotifier?.removeListener(callback);
    }
    _fieldNotifier?.dispose();
    _fieldNotifier = null;

    for (final callback in _filterCallbacks.values) {
      _filterNotifier?.removeListener(callback);
    }
    for (final callback in _sortCallbacks.values) {
      _sortNotifier?.removeListener(callback);
    }

    _filterNotifier?.dispose();
    _filterNotifier = null;

    _sortNotifier?.dispose();
    _sortNotifier = null;
  }

  Future<Either<Unit, FlowyError>> loadFields({
    required List<FieldIdPB> fieldIds,
  }) async {
    final result = await _databaseViewBackendSvc.getFields(fieldIds: fieldIds);
    return Future(
      () => result.fold(
        (newFields) {
          _fieldNotifier?.fieldInfos =
              newFields.map((field) => FieldInfo(field: field)).toList();
          _loadFilters();
          _loadSorts();
          _updateFieldInfos();
          return left(unit);
        },
        (err) => right(err),
      ),
    );
  }

  Future<Either<Unit, FlowyError>> _loadFilters() async {
    return _filterBackendSvc.getAllFilters().then((result) {
      return result.fold(
        (filterPBs) {
          final List<FilterInfo> filters = [];
          for (final filterPB in filterPBs) {
            final fieldInfo = _findFieldInfo(
              fieldInfos: fieldInfos,
              fieldId: filterPB.fieldId,
              fieldType: filterPB.fieldType,
            );
            if (fieldInfo != null) {
              final filterInfo = FilterInfo(viewId, filterPB, fieldInfo);
              filters.add(filterInfo);
            }
          }

          _filterNotifier?.filters = filters;
          return left(unit);
        },
        (err) => right(err),
      );
    });
  }

  Future<Either<Unit, FlowyError>> _loadSorts() async {
    return _sortBackendSvc.getAllSorts().then((result) {
      return result.fold(
        (sortPBs) {
          final List<SortInfo> sortInfos = [];
          for (final sortPB in sortPBs) {
            final fieldInfo = _findFieldInfo(
              fieldInfos: fieldInfos,
              fieldId: sortPB.fieldId,
              fieldType: sortPB.fieldType,
            );

            if (fieldInfo != null) {
              final sortInfo = SortInfo(sortPB: sortPB, fieldInfo: fieldInfo);
              sortInfos.add(sortInfo);
            }
          }

          _updateFieldInfos();
          _sortNotifier?.sorts = sortInfos;
          return left(unit);
        },
        (err) => right(err),
      );
    });
  }

  void addListener({
    OnReceiveFields? onReceiveFields,
    OnReceiveUpdateFields? onFieldsChanged,
    OnReceiveFilters? onFilters,
    OnReceiveSorts? onSorts,
    bool Function()? listenWhen,
  }) {
    if (onFieldsChanged != null) {
      callback(List<FieldInfo> updateFields) {
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
        onReceiveFields(fieldInfos);
      }

      _fieldCallbacks[onReceiveFields] = callback;
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
      _filterNotifier?.addListener(callback);
    }

    if (onSorts != null) {
      callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onSorts(sortInfos);
      }

      _sortCallbacks[onSorts] = callback;
      _sortNotifier?.addListener(callback);
    }
  }

  void removeListener({
    OnReceiveFields? onFieldsListener,
    OnReceiveSorts? onSortsListener,
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

    if (onSortsListener != null) {
      final callback = _sortCallbacks.remove(onSortsListener);
      if (callback != null) {
        _sortNotifier?.removeListener(callback);
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
    final List<FieldInfo> newFieldInfos = fieldInfos;
    for (final indexField in insertedFields) {
      final fieldInfo = FieldInfo(field: indexField.field_1);
      if (newFieldInfos.length > indexField.index) {
        newFieldInfos.insert(indexField.index, fieldInfo);
      } else {
        newFieldInfos.add(fieldInfo);
      }
    }
    _fieldNotifier?.fieldInfos = newFieldInfos;
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

class RowDelegatesImpl extends RowFieldsDelegate with RowCacheDelegate {
  final FieldController _cache;
  OnReceiveFields? _onFieldFn;
  RowDelegatesImpl(FieldController cache) : _cache = cache;

  @override
  UnmodifiableListView<FieldInfo> get fields =>
      UnmodifiableListView(_cache.fieldInfos);

  @override
  void onFieldsChanged(void Function(List<FieldInfo>) callback) {
    _onFieldFn = (fieldInfos) {
      callback(fieldInfos);
    };
    _cache.addListener(onReceiveFields: _onFieldFn);
  }

  @override
  void onRowDispose() {
    if (_onFieldFn != null) {
      _cache.removeListener(onFieldsListener: _onFieldFn!);
      _onFieldFn = null;
    }
  }
}

FieldInfo? _findFieldInfo({
  required List<FieldInfo> fieldInfos,
  required String fieldId,
  required FieldType fieldType,
}) {
  final fieldIndex = fieldInfos.indexWhere((element) {
    return element.id == fieldId && element.fieldType == fieldType;
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

  bool _hasSort = false;

  String get id => _field.id;

  FieldType get fieldType => _field.fieldType;

  bool get visibility => _field.visibility;

  double get width => _field.width.toDouble();

  bool get isPrimary => _field.isPrimary;

  String get name => _field.name;

  FieldPB get field => _field;

  bool get isGroupField => _isGroupField;

  bool get hasFilter => _hasFilter;

  bool get canBeGroup {
    switch (_field.fieldType) {
      case FieldType.URL:
      case FieldType.Checkbox:
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        return true;
      default:
        return false;
    }
  }

  bool get canCreateFilter {
    if (hasFilter) return false;

    switch (_field.fieldType) {
      case FieldType.Checkbox:
      case FieldType.MultiSelect:
      case FieldType.RichText:
      case FieldType.SingleSelect:
      case FieldType.Checklist:
        return true;
      default:
        return false;
    }
  }

  bool get canCreateSort {
    if (_hasSort) return false;

    switch (_field.fieldType) {
      case FieldType.RichText:
      case FieldType.Checkbox:
      case FieldType.Number:
        return true;
      default:
        return false;
    }
  }

  FieldInfo({required FieldPB field}) : _field = field;
}

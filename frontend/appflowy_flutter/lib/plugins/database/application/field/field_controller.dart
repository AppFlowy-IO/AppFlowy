import 'dart:collection';

import 'package:appflowy/plugins/database/domain/database_view_service.dart';
import 'package:appflowy/plugins/database/domain/field_listener.dart';
import 'package:appflowy/plugins/database/domain/field_settings_listener.dart';
import 'package:appflowy/plugins/database/domain/field_settings_service.dart';
import 'package:appflowy/plugins/database/domain/filter_listener.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/setting/setting_listener.dart';
import 'package:appflowy/plugins/database/domain/sort_listener.dart';
import 'package:appflowy/plugins/database/domain/sort_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/sort_info.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../setting/setting_service.dart';
import 'field_info.dart';

class _GridFieldNotifier extends ChangeNotifier {
  List<FieldInfo> _fieldInfos = [];

  set fieldInfos(List<FieldInfo> fieldInfos) {
    _fieldInfos = fieldInfos;
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  UnmodifiableListView<FieldInfo> get fieldInfos =>
      UnmodifiableListView(_fieldInfos);
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
typedef OnReceiveField = void Function(FieldInfo);
typedef OnReceiveFields = void Function(List<FieldInfo>);
typedef OnReceiveFilters = void Function(List<FilterInfo>);
typedef OnReceiveSorts = void Function(List<SortInfo>);
typedef OnReceiveFieldSettings = void Function(List<FieldInfo>);

class FieldController {
  FieldController({required this.viewId})
      : _fieldListener = FieldsListener(viewId: viewId),
        _settingListener = DatabaseSettingListener(viewId: viewId),
        _filterBackendSvc = FilterBackendService(viewId: viewId),
        _filtersListener = FiltersListener(viewId: viewId),
        _databaseViewBackendSvc = DatabaseViewBackendService(viewId: viewId),
        _sortBackendSvc = SortBackendService(viewId: viewId),
        _sortsListener = SortsListener(viewId: viewId),
        _fieldSettingsListener = FieldSettingsListener(viewId: viewId),
        _fieldSettingsBackendSvc = FieldSettingsBackendService(viewId: viewId) {
    // Start listeners
    _listenOnFieldChanges();
    _listenOnSettingChanges();
    _listenOnFilterChanges();
    _listenOnSortChanged();
    _listenOnFieldSettingsChanged();
  }

  final String viewId;

  // Listeners
  final FieldsListener _fieldListener;
  final DatabaseSettingListener _settingListener;
  final FiltersListener _filtersListener;
  final SortsListener _sortsListener;
  final FieldSettingsListener _fieldSettingsListener;

  // FFI services
  final DatabaseViewBackendService _databaseViewBackendSvc;
  final FilterBackendService _filterBackendSvc;
  final SortBackendService _sortBackendSvc;
  final FieldSettingsBackendService _fieldSettingsBackendSvc;

  bool _isDisposed = false;

  // Field callbacks
  final Map<OnReceiveFields, VoidCallback> _fieldCallbacks = {};
  final _GridFieldNotifier _fieldNotifier = _GridFieldNotifier();

  // Field updated callbacks
  final Map<OnReceiveUpdateFields, void Function(List<FieldInfo>)>
      _updatedFieldCallbacks = {};

  // Filter callbacks
  final Map<OnReceiveFilters, VoidCallback> _filterCallbacks = {};
  _GridFilterNotifier? _filterNotifier = _GridFilterNotifier();

  // Sort callbacks
  final Map<OnReceiveSorts, VoidCallback> _sortCallbacks = {};
  _GridSortNotifier? _sortNotifier = _GridSortNotifier();

  // Database settings temporary storage
  final Map<String, GroupSettingPB> _groupConfigurationByFieldId = {};
  final List<FieldSettingsPB> _fieldSettings = [];

  // Getters
  List<FieldInfo> get fieldInfos => [..._fieldNotifier.fieldInfos];
  List<FilterInfo> get filterInfos => [..._filterNotifier?.filters ?? []];
  List<SortInfo> get sortInfos => [..._sortNotifier?.sorts ?? []];

  FieldInfo? getField(String fieldId) {
    return _fieldNotifier.fieldInfos
        .firstWhereOrNull((element) => element.id == fieldId);
  }

  FilterInfo? getFilterByFilterId(String filterId) {
    return _filterNotifier?.filters
        .firstWhereOrNull((element) => element.filterId == filterId);
  }

  FilterInfo? getFilterByFieldId(String fieldId) {
    return _filterNotifier?.filters
        .firstWhereOrNull((element) => element.fieldId == fieldId);
  }

  SortInfo? getSortBySortId(String sortId) {
    return _sortNotifier?.sorts
        .firstWhereOrNull((element) => element.sortId == sortId);
  }

  SortInfo? getSortByFieldId(String fieldId) {
    return _sortNotifier?.sorts
        .firstWhereOrNull((element) => element.fieldId == fieldId);
  }

  /// Listen for filter changes in the backend.
  void _listenOnFilterChanges() {
    _filtersListener.start(
      onFilterChanged: (result) {
        if (_isDisposed) {
          return;
        }

        result.fold(
          (FilterChangesetNotificationPB changeset) {
            final List<FilterInfo> filters = [];
            for (final filter in changeset.filters.items) {
              final fieldInfo = _findFieldInfo(
                fieldInfos: fieldInfos,
                fieldId: filter.data.fieldId,
                fieldType: filter.data.fieldType,
              );

              if (fieldInfo != null) {
                final filterInfo = FilterInfo(viewId, filter, fieldInfo);
                filters.add(filterInfo);
              }
            }

            _filterNotifier?.filters = filters;
            _updateFieldInfos();
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  /// Listen for sort changes in the backend.
  void _listenOnSortChanged() {
    void deleteSortFromChangeset(
      List<SortInfo> newSortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      final deleteSortIds = changeset.deleteSorts.map((e) => e.id).toList();
      if (deleteSortIds.isNotEmpty) {
        newSortInfos.retainWhere(
          (element) => !deleteSortIds.contains(element.sortId),
        );
      }
    }

    void insertSortFromChangeset(
      List<SortInfo> newSortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      for (final newSortPB in changeset.insertSorts) {
        final sortIndex = newSortInfos
            .indexWhere((element) => element.sortId == newSortPB.sort.id);
        if (sortIndex == -1) {
          final fieldInfo = _findFieldInfo(
            fieldInfos: fieldInfos,
            fieldId: newSortPB.sort.fieldId,
            fieldType: null,
          );

          if (fieldInfo != null) {
            newSortInfos.insert(
              newSortPB.index,
              SortInfo(sortPB: newSortPB.sort, fieldInfo: fieldInfo),
            );
          }
        }
      }
    }

    void updateSortFromChangeset(
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
          fieldType: null,
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
        }
      }
    }

    void updateFieldInfos(
      List<SortInfo> newSortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      final changedFieldIds = HashSet<String>.from([
        ...changeset.insertSorts.map((sort) => sort.sort.fieldId),
        ...changeset.updateSorts.map((sort) => sort.fieldId),
        ...changeset.deleteSorts.map((sort) => sort.fieldId),
        ...?_sortNotifier?.sorts.map((sort) => sort.fieldId),
      ]);

      final newFieldInfos = [...fieldInfos];

      for (final fieldId in changedFieldIds) {
        final index =
            newFieldInfos.indexWhere((fieldInfo) => fieldInfo.id == fieldId);
        if (index == -1) {
          continue;
        }
        newFieldInfos[index] = newFieldInfos[index].copyWith(
          hasSort: newSortInfos.any((sort) => sort.fieldId == fieldId),
        );
      }

      _fieldNotifier.fieldInfos = newFieldInfos;
    }

    _sortsListener.start(
      onSortChanged: (result) {
        if (_isDisposed) {
          return;
        }
        result.fold(
          (SortChangesetNotificationPB changeset) {
            final List<SortInfo> newSortInfos = sortInfos;
            deleteSortFromChangeset(newSortInfos, changeset);
            insertSortFromChangeset(newSortInfos, changeset);
            updateSortFromChangeset(newSortInfos, changeset);

            updateFieldInfos(newSortInfos, changeset);
            _sortNotifier?.sorts = newSortInfos;
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  /// Listen for database setting changes in the backend.
  void _listenOnSettingChanges() {
    _settingListener.start(
      onSettingUpdated: (result) {
        if (_isDisposed) {
          return;
        }

        result.fold(
          (setting) => _updateSetting(setting),
          (r) => Log.error(r),
        );
      },
    );
  }

  /// Listen for field changes in the backend.
  void _listenOnFieldChanges() {
    Future<FieldInfo> attachFieldSettings(FieldInfo fieldInfo) async {
      return _fieldSettingsBackendSvc
          .getFieldSettings(fieldInfo.id)
          .then((result) {
        final fieldSettings = result.fold(
          (fieldSettings) => fieldSettings,
          (err) => null,
        );
        if (fieldSettings == null) {
          return fieldInfo;
        }
        final updatedFieldInfo =
            fieldInfo.copyWith(fieldSettings: fieldSettings);

        final index = _fieldSettings
            .indexWhere((element) => element.fieldId == fieldInfo.id);
        if (index != -1) {
          _fieldSettings.removeAt(index);
        }
        _fieldSettings.add(fieldSettings);

        return updatedFieldInfo;
      });
    }

    List<FieldInfo> deleteFields(List<FieldIdPB> deletedFields) {
      if (deletedFields.isEmpty) {
        return fieldInfos;
      }
      final List<FieldInfo> newFields = fieldInfos;
      final Map<String, FieldIdPB> deletedFieldMap = {
        for (final fieldOrder in deletedFields) fieldOrder.fieldId: fieldOrder,
      };

      newFields.retainWhere((field) => deletedFieldMap[field.id] == null);
      return newFields;
    }

    Future<List<FieldInfo>> insertFields(
      List<IndexFieldPB> insertedFields,
      List<FieldInfo> fieldInfos,
    ) async {
      if (insertedFields.isEmpty) {
        return fieldInfos;
      }
      final List<FieldInfo> newFieldInfos = fieldInfos;
      for (final indexField in insertedFields) {
        final initial = FieldInfo.initial(indexField.field_1);
        final fieldInfo = await attachFieldSettings(initial);
        if (newFieldInfos.length > indexField.index) {
          newFieldInfos.insert(indexField.index, fieldInfo);
        } else {
          newFieldInfos.add(fieldInfo);
        }
      }
      return newFieldInfos;
    }

    Future<(List<FieldInfo>, List<FieldInfo>)> updateFields(
      List<FieldPB> updatedFieldPBs,
      List<FieldInfo> fieldInfos,
    ) async {
      if (updatedFieldPBs.isEmpty) {
        return (<FieldInfo>[], fieldInfos);
      }

      final List<FieldInfo> newFieldInfo = fieldInfos;
      final List<FieldInfo> updatedFields = [];
      for (final updatedFieldPB in updatedFieldPBs) {
        final index =
            newFieldInfo.indexWhere((field) => field.id == updatedFieldPB.id);
        if (index != -1) {
          newFieldInfo.removeAt(index);
          final initial = FieldInfo.initial(updatedFieldPB);
          final fieldInfo = await attachFieldSettings(initial);
          newFieldInfo.insert(index, fieldInfo);
          updatedFields.add(fieldInfo);
        }
      }

      return (updatedFields, newFieldInfo);
    }

    // Listen on field's changes
    _fieldListener.start(
      onFieldsChanged: (result) async {
        result.fold(
          (changeset) async {
            if (_isDisposed) {
              return;
            }
            List<FieldInfo> updatedFields;
            List<FieldInfo> fieldInfos = deleteFields(changeset.deletedFields);
            fieldInfos =
                await insertFields(changeset.insertedFields, fieldInfos);
            (updatedFields, fieldInfos) =
                await updateFields(changeset.updatedFields, fieldInfos);

            _fieldNotifier.fieldInfos = fieldInfos;
            for (final listener in _updatedFieldCallbacks.values) {
              listener(updatedFields);
            }
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  /// Listen for field setting changes in the backend.
  void _listenOnFieldSettingsChanged() {
    FieldInfo updateFieldSettings(FieldSettingsPB updatedFieldSettings) {
      final List<FieldInfo> newFields = fieldInfos;
      FieldInfo updatedField = newFields[0];

      final index = newFields
          .indexWhere((field) => field.id == updatedFieldSettings.fieldId);
      if (index != -1) {
        newFields[index] =
            newFields[index].copyWith(fieldSettings: updatedFieldSettings);
        updatedField = newFields[index];
      }

      _fieldNotifier.fieldInfos = newFields;
      return updatedField;
    }

    _fieldSettingsListener.start(
      onFieldSettingsChanged: (result) {
        if (_isDisposed) {
          return;
        }
        result.fold(
          (fieldSettings) {
            final updatedFieldInfo = updateFieldSettings(fieldSettings);
            for (final listener in _updatedFieldCallbacks.values) {
              listener([updatedFieldInfo]);
            }
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  /// Updates sort, filter, group and field info from `DatabaseViewSettingPB`
  void _updateSetting(DatabaseViewSettingPB setting) {
    _groupConfigurationByFieldId.clear();
    for (final configuration in setting.groupSettings.items) {
      _groupConfigurationByFieldId[configuration.fieldId] = configuration;
    }

    _filterNotifier?.filters = _filterInfoListFromPBs(setting.filters.items);

    _sortNotifier?.sorts = _sortInfoListFromPBs(setting.sorts.items);

    _fieldSettings.clear();
    _fieldSettings.addAll(setting.fieldSettings.items);

    _updateFieldInfos();
  }

  /// Attach sort, filter, group information and field settings to `FieldInfo`
  void _updateFieldInfos() {
    final List<FieldInfo> newFieldInfos = [];
    for (final field in _fieldNotifier.fieldInfos) {
      newFieldInfos.add(
        field.copyWith(
          fieldSettings: _fieldSettings
              .firstWhereOrNull((setting) => setting.fieldId == field.id),
          isGroupField: _groupConfigurationByFieldId[field.id] != null,
          hasFilter: getFilterByFieldId(field.id) != null,
          hasSort: getSortByFieldId(field.id) != null,
        ),
      );
    }

    _fieldNotifier.fieldInfos = newFieldInfos;
  }

  /// Load all of the fields. This is required when opening the database
  Future<FlowyResult<void, FlowyError>> loadFields({
    required List<FieldIdPB> fieldIds,
  }) async {
    final result = await _databaseViewBackendSvc.getFields(fieldIds: fieldIds);
    return Future(
      () => result.fold(
        (newFields) async {
          if (_isDisposed) {
            return FlowyResult.success(null);
          }

          _fieldNotifier.fieldInfos =
              newFields.map((field) => FieldInfo.initial(field)).toList();
          await Future.wait([
            _loadFilters(),
            _loadSorts(),
            _loadAllFieldSettings(),
            _loadSettings(),
          ]);
          _updateFieldInfos();

          return FlowyResult.success(null);
        },
        (err) => FlowyResult.failure(err),
      ),
    );
  }

  /// Load all the filters from the backend. Required by `loadFields`
  Future<FlowyResult<void, FlowyError>> _loadFilters() async {
    return _filterBackendSvc.getAllFilters().then((result) {
      return result.fold(
        (filterPBs) {
          _filterNotifier?.filters = _filterInfoListFromPBs(filterPBs);
          return FlowyResult.success(null);
        },
        (err) => FlowyResult.failure(err),
      );
    });
  }

  /// Load all the sorts from the backend. Required by `loadFields`
  Future<FlowyResult<void, FlowyError>> _loadSorts() async {
    return _sortBackendSvc.getAllSorts().then((result) {
      return result.fold(
        (sortPBs) {
          _sortNotifier?.sorts = _sortInfoListFromPBs(sortPBs);
          return FlowyResult.success(null);
        },
        (err) => FlowyResult.failure(err),
      );
    });
  }

  /// Load all the field settings from the backend. Required by `loadFields`
  Future<FlowyResult<void, FlowyError>> _loadAllFieldSettings() async {
    return _fieldSettingsBackendSvc.getAllFieldSettings().then((result) {
      return result.fold(
        (fieldSettingsList) {
          _fieldSettings.clear();
          _fieldSettings.addAll(fieldSettingsList);
          return FlowyResult.success(null);
        },
        (err) => FlowyResult.failure(err),
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> _loadSettings() async {
    return SettingBackendService(viewId: viewId).getSetting().then(
          (result) => result.fold(
            (setting) {
              _groupConfigurationByFieldId.clear();
              for (final configuration in setting.groupSettings.items) {
                _groupConfigurationByFieldId[configuration.fieldId] =
                    configuration;
              }
              return FlowyResult.success(null);
            },
            (err) => FlowyResult.failure(err),
          ),
        );
  }

  /// Attach corresponding `FieldInfo`s to the `FilterPB`s
  List<FilterInfo> _filterInfoListFromPBs(List<FilterPB> filterPBs) {
    FilterInfo? getFilterInfo(FilterPB filterPB) {
      final fieldInfo = _findFieldInfo(
        fieldInfos: fieldInfos,
        fieldId: filterPB.data.fieldId,
        fieldType: filterPB.data.fieldType,
      );
      return fieldInfo != null ? FilterInfo(viewId, filterPB, fieldInfo) : null;
    }

    return filterPBs
        .map((filterPB) => getFilterInfo(filterPB))
        .whereType<FilterInfo>()
        .toList();
  }

  /// Attach corresponding `FieldInfo`s to the `SortPB`s
  List<SortInfo> _sortInfoListFromPBs(List<SortPB> sortPBs) {
    SortInfo? getSortInfo(SortPB sortPB) {
      final fieldInfo = _findFieldInfo(
        fieldInfos: fieldInfos,
        fieldId: sortPB.fieldId,
        fieldType: null,
      );
      return fieldInfo != null
          ? SortInfo(sortPB: sortPB, fieldInfo: fieldInfo)
          : null;
    }

    return sortPBs
        .map((sortPB) => getSortInfo(sortPB))
        .whereType<SortInfo>()
        .toList();
  }

  void addListener({
    OnReceiveFields? onReceiveFields,
    OnReceiveUpdateFields? onFieldsChanged,
    OnReceiveFilters? onFilters,
    OnReceiveSorts? onSorts,
    bool Function()? listenWhen,
  }) {
    if (onFieldsChanged != null) {
      void callback(List<FieldInfo> updateFields) {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onFieldsChanged(updateFields);
      }

      _updatedFieldCallbacks[onFieldsChanged] = callback;
    }

    if (onReceiveFields != null) {
      void callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onReceiveFields(fieldInfos);
      }

      _fieldCallbacks[onReceiveFields] = callback;
      _fieldNotifier.addListener(callback);
    }

    if (onFilters != null) {
      void callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onFilters(filterInfos);
      }

      _filterCallbacks[onFilters] = callback;
      _filterNotifier?.addListener(callback);
    }

    if (onSorts != null) {
      void callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onSorts(sortInfos);
      }

      _sortCallbacks[onSorts] = callback;
      _sortNotifier?.addListener(callback);
    }
  }

  void addSingleFieldListener(
    String fieldId, {
    required OnReceiveField onFieldChanged,
    bool Function()? listenWhen,
  }) {
    void key(List<FieldInfo> fieldInfos) {
      final fieldInfo = fieldInfos.firstWhereOrNull(
        (fieldInfo) => fieldInfo.id == fieldId,
      );
      if (fieldInfo != null) {
        onFieldChanged(fieldInfo);
      }
    }

    void callback() {
      if (listenWhen != null && listenWhen() == false) {
        return;
      }
      key(fieldInfos);
    }

    _fieldCallbacks[key] = callback;
    _fieldNotifier.addListener(callback);
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
        _fieldNotifier.removeListener(callback);
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

  void removeSingleFieldListener({
    required String fieldId,
    required OnReceiveField onFieldChanged,
  }) {
    void key(List<FieldInfo> fieldInfos) {
      final fieldInfo = fieldInfos.firstWhereOrNull(
        (fieldInfo) => fieldInfo.id == fieldId,
      );
      if (fieldInfo != null) {
        onFieldChanged(fieldInfo);
      }
    }

    final callback = _fieldCallbacks.remove(key);
    if (callback != null) {
      _fieldNotifier.removeListener(callback);
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
    await _filtersListener.stop();
    await _settingListener.stop();
    await _sortsListener.stop();
    await _fieldSettingsListener.stop();

    for (final callback in _fieldCallbacks.values) {
      _fieldNotifier.removeListener(callback);
    }
    _fieldNotifier.dispose();

    for (final callback in _filterCallbacks.values) {
      _filterNotifier?.removeListener(callback);
    }
    _filterNotifier?.dispose();
    _filterNotifier = null;

    for (final callback in _sortCallbacks.values) {
      _sortNotifier?.removeListener(callback);
    }
    _sortNotifier?.dispose();
    _sortNotifier = null;
  }
}

class RowCacheDependenciesImpl extends RowFieldsDelegate with RowLifeCycle {
  RowCacheDependenciesImpl(FieldController cache) : _fieldController = cache;

  final FieldController _fieldController;
  OnReceiveFields? _onFieldFn;

  @override
  UnmodifiableListView<FieldInfo> get fieldInfos =>
      UnmodifiableListView(_fieldController.fieldInfos);

  @override
  void onFieldsChanged(void Function(List<FieldInfo>) callback) {
    if (_onFieldFn != null) {
      _fieldController.removeListener(onFieldsListener: _onFieldFn!);
    }

    _onFieldFn = (fieldInfos) => callback(fieldInfos);
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

FieldInfo? _findFieldInfo({
  required List<FieldInfo> fieldInfos,
  required String fieldId,
  required FieldType? fieldType,
}) {
  return fieldInfos.firstWhereOrNull(
    (element) =>
        element.id == fieldId &&
        (fieldType == null || element.fieldType == fieldType),
  );
}

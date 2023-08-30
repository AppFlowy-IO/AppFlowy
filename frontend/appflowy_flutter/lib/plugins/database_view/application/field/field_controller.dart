import 'package:appflowy/plugins/database_view/application/database_view_service.dart';
import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_listener.dart';
import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_service.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_listener.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/setting/setting_listener.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_listener.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/sort/sort_info.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/filter_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'field_info.dart';
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
typedef OnReceiveFields = void Function(List<FieldInfo>);
typedef OnReceiveFilters = void Function(List<FilterInfo>);
typedef OnReceiveSorts = void Function(List<SortInfo>);
typedef OnReceiveFieldSettings = void Function(List<FieldInfo>);

class FieldController {
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

  /// Listen for filter changes in the backend.
  void _listenOnFilterChanges() {
    deleteFilterFromChangeset(
      List<FilterInfo> filters,
      FilterChangesetNotificationPB changeset,
    ) {
      final deleteFilterIds = changeset.deleteFilters.map((e) => e.id).toList();
      if (deleteFilterIds.isNotEmpty) {
        filters.retainWhere(
          (element) => !deleteFilterIds.contains(element.filter.id),
        );
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
          }
        }
      }
    }

    _filtersListener.start(
      onFilterChanged: (result) {
        if (_isDisposed) {
          return;
        }

        result.fold(
          (FilterChangesetNotificationPB changeset) {
            final List<FilterInfo> filters = filterInfos;
            // delete removed filters
            deleteFilterFromChangeset(filters, changeset);

            // insert new filters
            insertFilterFromChangeset(filters, changeset);

            // edit modified filters
            updateFilterFromChangeset(filters, changeset);

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
    deleteSortFromChangeset(
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
        }
      }
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

            _sortNotifier?.sorts = newSortInfos;
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  /// Listen for databse setting changes in the backend.
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
    void deleteFields(List<FieldIdPB> deletedFields) {
      if (deletedFields.isEmpty) {
        return;
      }
      final List<FieldInfo> newFields = fieldInfos;
      final Map<String, FieldIdPB> deletedFieldMap = {
        for (var fieldOrder in deletedFields) fieldOrder.fieldId: fieldOrder
      };

      newFields.retainWhere((field) => (deletedFieldMap[field.id] == null));
      _fieldNotifier.fieldInfos = newFields;
    }

    Future<FieldInfo> attachFieldSettings(FieldInfo fieldInfo) async {
      return _fieldSettingsBackendSvc
          .getFieldSettings(fieldInfo.id)
          .then((result) {
        final fieldSettings = result.fold(
          (fieldSettings) => fieldSettings,
          (err) {
            return null;
          },
        );
        if (fieldSettings == null) {
          return fieldInfo;
        }
        final updatedFieldInfo =
            fieldInfo.copyWith(fieldSettings: fieldSettings);

        return updatedFieldInfo;
      });
    }

    Future<void> insertFields(List<IndexFieldPB> insertedFields) async {
      if (insertedFields.isEmpty) {
        return;
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
      _fieldNotifier.fieldInfos = newFieldInfos;
    }

    Future<List<FieldInfo>> updateFields(List<FieldPB> updatedFieldPBs) async {
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
          final initial = FieldInfo.initial(updatedFieldPB);
          final fieldInfo = await attachFieldSettings(initial);
          newFields.insert(index, fieldInfo);
          updatedFields.add(fieldInfo);
        }
      }

      if (updatedFields.isNotEmpty) {
        _fieldNotifier.fieldInfos = newFields;
      }
      return updatedFields;
    }

    // Listen on field's changes
    _fieldListener.start(
      onFieldsChanged: (result) async {
        result.fold(
          (changeset) async {
            if (_isDisposed) {
              return;
            }
            deleteFields(changeset.deletedFields);
            insertFields(changeset.insertedFields);

            final updatedFields = await updateFields(changeset.updatedFields);
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
  Future<Either<Unit, FlowyError>> loadFields({
    required List<FieldIdPB> fieldIds,
  }) async {
    final result = await _databaseViewBackendSvc.getFields(fieldIds: fieldIds);
    return Future(
      () => result.fold(
        (newFields) async {
          if (_isDisposed) {
            return left(unit);
          }

          _fieldNotifier.fieldInfos =
              newFields.map((field) => FieldInfo.initial(field)).toList();
          await Future.wait([
            _loadFilters(),
            _loadSorts(),
            _loadAllFieldSettings(),
          ]);
          _updateFieldInfos();

          return left(unit);
        },
        (err) => right(err),
      ),
    );
  }

  /// Load all the filters from the backend. Required by `loadFields`
  Future<Either<Unit, FlowyError>> _loadFilters() async {
    return _filterBackendSvc.getAllFilters().then((result) {
      return result.fold(
        (filterPBs) {
          _filterNotifier?.filters = _filterInfoListFromPBs(filterPBs);
          return left(unit);
        },
        (err) => right(err),
      );
    });
  }

  /// Load all the sorts from the backend. Required by `loadFields`
  Future<Either<Unit, FlowyError>> _loadSorts() async {
    return _sortBackendSvc.getAllSorts().then((result) {
      return result.fold(
        (sortPBs) {
          _sortNotifier?.sorts = _sortInfoListFromPBs(sortPBs);
          return left(unit);
        },
        (err) => right(err),
      );
    });
  }

  /// Load all the field settings from the backend. Required by `loadFields`
  Future<Either<Unit, FlowyError>> _loadAllFieldSettings() async {
    return _fieldSettingsBackendSvc.getAllFieldSettings().then((result) {
      return result.fold(
        (fieldSettingsList) {
          _fieldSettings.clear();
          _fieldSettings.addAll(fieldSettingsList);
          return left(unit);
        },
        (err) => right(err),
      );
    });
  }

  /// Attach corresponding `FieldInfo`s to the `FilterPB`s
  List<FilterInfo> _filterInfoListFromPBs(List<FilterPB> filterPBs) {
    FilterInfo? getFilterInfo(FilterPB filterPB) {
      final fieldInfo = _findFieldInfo(
        fieldInfos: fieldInfos,
        fieldId: filterPB.fieldId,
        fieldType: filterPB.fieldType,
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
        fieldType: sortPB.fieldType,
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
      _fieldNotifier.addListener(callback);
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
  final FieldController _fieldController;
  OnReceiveFields? _onFieldFn;
  RowCacheDependenciesImpl(FieldController cache) : _fieldController = cache;

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
  required FieldType fieldType,
}) {
  return fieldInfos.firstWhereOrNull(
    (element) => element.id == fieldId && element.fieldType == fieldType,
  );
}

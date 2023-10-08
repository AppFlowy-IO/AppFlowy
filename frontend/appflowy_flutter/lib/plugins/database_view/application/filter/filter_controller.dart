import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_listener.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/filter_changeset.pb.dart';
import 'package:flutter/widgets.dart';

import 'filter_info.dart';

typedef OnReceiveFilters = void Function(List<FilterInfo>);

class _FilterNotifier extends ChangeNotifier {
  List<FilterInfo> _filters = [];

  set filters(List<FilterInfo> filters) {
    _filters = filters;
    notifyListeners();
  }

  List<FilterInfo> get filters => _filters;
}

class FilterController {
  final FilterBackendService service;
  final FieldController fieldController;
  final FiltersListener _listener;
  final Map<OnReceiveFilters, VoidCallback> _filterCallbacks = {};
  _FilterNotifier? _filterNotifier = _FilterNotifier();

  bool _isDisposed = false;

  List<FilterInfo> get filters => [..._filterNotifier?.filters ?? []];

  FilterController({
    required this.fieldController,
  })  : service = FilterBackendService(viewId: fieldController.viewId),
        _listener = FiltersListener(viewId: fieldController.viewId) {
    _startFieldListener();
    _startFilterListener();
  }

  // Listen for field changes in the backend.
  void _startFieldListener() {
    fieldController.addListener(
      onFieldsChanged: (fields) {
        if (fields.isEmpty) {
          return;
        }
        final currentFilters = filters;
        for (final field in fields) {
          final index =
              currentFilters.indexWhere((filter) => filter.fieldId == field.id);
          if (index != -1) {
            final filterInfo = FilterInfo(
              filter: currentFilters[index].filter,
              field: field,
            );
            currentFilters.removeAt(index);
            currentFilters.insert(index, filterInfo);
          }
        }
        _filterNotifier?.filters = currentFilters;
      },
    );
  }

  /// Listen for filter changes in the backend.
  void _startFilterListener() {
    deleteFilterFromChangeset(
      List<FilterInfo> filterInfos,
      FilterChangesetNotificationPB changeset,
    ) {
      if (changeset.deleteFilters.isEmpty) {
        return;
      }
      final deleteFilterIds =
          changeset.deleteFilters.map((filter) => filter.id).toList();
      filterInfos.retainWhere(
        (filterInfo) => !deleteFilterIds.contains(filterInfo.filterId),
      );
    }

    insertFilterFromChangeset(
      List<FilterInfo> filterInfos,
      FilterChangesetNotificationPB changeset,
    ) {
      if (changeset.insertFilters.isEmpty) {
        return;
      }
      for (final newFilter in changeset.insertFilters) {
        final filterIndex =
            filterInfos.indexWhere((filter) => filter.filterId == newFilter.id);
        if (filterIndex == -1) {
          final field =
              fieldController.getField(newFilter.fieldId, newFilter.fieldType);
          if (field != null) {
            filterInfos.add(FilterInfo(filter: newFilter, field: field));
          }
        }
      }
    }

    updateFilterFromChangeset(
      List<FilterInfo> filterInfos,
      FilterChangesetNotificationPB changeset,
    ) {
      if (changeset.updateFilters.isEmpty) {
        return;
      }
      for (final updatedFilter in changeset.updateFilters) {
        final oldIndex = filterInfos.indexWhere(
          (filterInfo) => filterInfo.filterId == updatedFilter.filterId,
        );

        final field = fieldController.getField(
          updatedFilter.filter.fieldId,
          updatedFilter.filter.fieldType,
        );

        if (field == null || !updatedFilter.hasFilter()) {
          continue;
        }
        final newFilterInfo = FilterInfo(
          filter: updatedFilter.filter,
          field: field,
        );
        if (oldIndex != -1) {
          filterInfos.removeAt(oldIndex);
          filterInfos.insert(oldIndex, newFilterInfo);
        } else {
          filterInfos.add(newFilterInfo);
        }
      }
    }

    _listener.start(
      onFilterChanged: (result) {
        if (_isDisposed) {
          return;
        }
        result.fold(
          (FilterChangesetNotificationPB changeset) {
            final List<FilterInfo> newFilterInfos = filters;
            deleteFilterFromChangeset(newFilterInfos, changeset);
            insertFilterFromChangeset(newFilterInfos, changeset);
            updateFilterFromChangeset(newFilterInfos, changeset);

            _filterNotifier?.filters = newFilterInfos;
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  void addListener({
    OnReceiveFilters? onReceiveFilters,
    bool Function()? listenWhen,
  }) {
    if (onReceiveFilters != null) {
      callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onReceiveFilters(filters);
      }

      _filterCallbacks[onReceiveFilters] = callback;
      _filterNotifier?.addListener(callback);
    }
  }

  void removeListener({required OnReceiveFilters onFiltersListener}) {
    final callback = _filterCallbacks.remove(onFiltersListener);
    if (callback != null) {
      _filterNotifier?.removeListener(callback);
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      Log.warn('FilterController is already disposed.');
      return;
    }
    _isDisposed = true;
    await _listener.stop();
    for (final callback in _filterCallbacks.values) {
      _filterNotifier?.removeListener(callback);
    }
    _filterNotifier?.dispose();
    _filterNotifier = null;
  }
}

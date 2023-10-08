import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_listener.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';
import 'package:flutter/widgets.dart';

import 'sort_info.dart';

typedef OnReceiveSorts = void Function(List<SortInfo>);

class _SortNotifier extends ChangeNotifier {
  List<SortInfo> _sorts = [];

  set sorts(List<SortInfo> sorts) {
    _sorts = sorts;
    notifyListeners();
  }

  List<SortInfo> get sorts => _sorts;
}

class SortController {
  final SortBackendService service;
  final FieldController fieldController;
  final SortListener _listener;
  final Map<OnReceiveSorts, VoidCallback> _sortCallbacks = {};
  _SortNotifier? _sortNotifier = _SortNotifier();

  bool _isDisposed = false;

  List<SortInfo> get sorts => [..._sortNotifier?.sorts ?? []];

  SortController({
    required this.fieldController,
  })  : service = SortBackendService(viewId: fieldController.viewId),
        _listener = SortListener(viewId: fieldController.viewId) {
    _startFieldListener();
    _startSortListener();
  }

  // Listen for field changes in the backend.
  void _startFieldListener() {
    fieldController.addListener(
      onFieldsChanged: (fields) {
        if (fields.isEmpty) {
          return;
        }
        final currentSorts = sorts;
        for (final field in fields) {
          final index =
              currentSorts.indexWhere((sort) => sort.fieldId == field.id);
          if (index != -1) {
            final sortInfo =
                SortInfo(sort: currentSorts[index].sort, field: field);
            currentSorts.removeAt(index);
            currentSorts.insert(index, sortInfo);
          }
        }
        _sortNotifier?.sorts = currentSorts;
      },
    );
  }

  /// Listen for sort changes in the backend.
  void _startSortListener() {
    deleteSortFromChangeset(
      List<SortInfo> sortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      if (changeset.deleteSorts.isEmpty) {
        return;
      }
      final deleteSortIds =
          changeset.deleteSorts.map((sort) => sort.id).toList();
      sortInfos.retainWhere(
        (sortInfo) => !deleteSortIds.contains(sortInfo.sortId),
      );
    }

    insertSortFromChangeset(
      List<SortInfo> sortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      if (changeset.insertSorts.isEmpty) {
        return;
      }
      for (final newSort in changeset.insertSorts) {
        final sortIndex =
            sortInfos.indexWhere((sort) => sort.sortId == newSort.id);
        if (sortIndex == -1) {
          final field =
              fieldController.getField(newSort.fieldId, newSort.fieldType);
          if (field != null) {
            sortInfos.add(SortInfo(sort: newSort, field: field));
          }
        }
      }
    }

    updateSortFromChangeset(
      List<SortInfo> sortInfos,
      SortChangesetNotificationPB changeset,
    ) {
      if (changeset.updateSorts.isEmpty) {
        return;
      }
      for (final updatedSort in changeset.updateSorts) {
        final oldIndex = sortInfos.indexWhere(
          (sortInfo) => sortInfo.sortId == updatedSort.id,
        );

        final field = fieldController.getField(
          updatedSort.fieldId,
          updatedSort.fieldType,
        );

        if (field == null) {
          continue;
        }
        final newSortInfo = SortInfo(
          sort: updatedSort,
          field: field,
        );
        if (oldIndex != -1) {
          sortInfos.removeAt(oldIndex);
          sortInfos.insert(oldIndex, newSortInfo);
        } else {
          sortInfos.add(newSortInfo);
        }
      }
    }

    _listener.start(
      onSortChanged: (result) {
        if (_isDisposed) {
          return;
        }
        result.fold(
          (SortChangesetNotificationPB changeset) {
            final List<SortInfo> newSortInfos = sorts;
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

  void addListener({
    OnReceiveSorts? onReceiveSorts,
    bool Function()? listenWhen,
  }) {
    if (onReceiveSorts != null) {
      callback() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onReceiveSorts(sorts);
      }

      _sortCallbacks[onReceiveSorts] = callback;
      _sortNotifier?.addListener(callback);
    }
  }

  void removeListener({required OnReceiveSorts onSortsListener}) {
    final callback = _sortCallbacks.remove(onSortsListener);
    if (callback != null) {
      _sortNotifier?.removeListener(callback);
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      Log.warn('SortController is already disposed.');
      return;
    }
    _isDisposed = true;
    await _listener.stop();
    for (final callback in _sortCallbacks.values) {
      _sortNotifier?.removeListener(callback);
    }
    _sortNotifier?.dispose();
    _sortNotifier = null;
  }
}

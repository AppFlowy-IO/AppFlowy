import 'dart:collection';

import 'package:app_flowy/plugins/grid/application/field/grid_listener.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/foundation.dart';

import '../row/row_cache.dart';

class FieldsNotifier extends ChangeNotifier {
  List<GridFieldPB> _fields = [];

  set fields(List<GridFieldPB> fields) {
    _fields = fields;
    notifyListeners();
  }

  List<GridFieldPB> get fields => _fields;
}

typedef FieldChangesetCallback = void Function(GridFieldChangesetPB);
typedef FieldsCallback = void Function(List<GridFieldPB>);

class GridFieldCache {
  final String gridId;
  final GridFieldsListener _fieldListener;
  FieldsNotifier? _fieldNotifier = FieldsNotifier();
  final Map<FieldsCallback, VoidCallback> _fieldsCallbackMap = {};
  final Map<FieldChangesetCallback, FieldChangesetCallback>
      _changesetCallbackMap = {};

  GridFieldCache({required this.gridId})
      : _fieldListener = GridFieldsListener(gridId: gridId) {
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
  }

  Future<void> dispose() async {
    await _fieldListener.stop();
    _fieldNotifier?.dispose();
    _fieldNotifier = null;
  }

  UnmodifiableListView<GridFieldPB> get unmodifiableFields =>
      UnmodifiableListView(_fieldNotifier?.fields ?? []);

  List<GridFieldPB> get fields => [..._fieldNotifier?.fields ?? []];

  set fields(List<GridFieldPB> fields) {
    _fieldNotifier?.fields = [...fields];
  }

  void addListener({
    FieldsCallback? onFields,
    FieldChangesetCallback? onChangeset,
    bool Function()? listenWhen,
  }) {
    if (onChangeset != null) {
      fn(c) {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onChangeset(c);
      }

      _changesetCallbackMap[onChangeset] = fn;
    }

    if (onFields != null) {
      fn() {
        if (listenWhen != null && listenWhen() == false) {
          return;
        }
        onFields(fields);
      }

      _fieldsCallbackMap[onFields] = fn;
      _fieldNotifier?.addListener(fn);
    }
  }

  void removeListener({
    FieldsCallback? onFieldsListener,
    FieldChangesetCallback? onChangesetListener,
  }) {
    if (onFieldsListener != null) {
      final fn = _fieldsCallbackMap.remove(onFieldsListener);
      if (fn != null) {
        _fieldNotifier?.removeListener(fn);
      }
    }

    if (onChangesetListener != null) {
      _changesetCallbackMap.remove(onChangesetListener);
    }
  }

  void _deleteFields(List<GridFieldIdPB> deletedFields) {
    if (deletedFields.isEmpty) {
      return;
    }
    final List<GridFieldPB> newFields = fields;
    final Map<String, GridFieldIdPB> deletedFieldMap = {
      for (var fieldOrder in deletedFields) fieldOrder.fieldId: fieldOrder
    };

    newFields.retainWhere((field) => (deletedFieldMap[field.id] == null));
    _fieldNotifier?.fields = newFields;
  }

  void _insertFields(List<IndexFieldPB> insertedFields) {
    if (insertedFields.isEmpty) {
      return;
    }
    final List<GridFieldPB> newFields = fields;
    for (final indexField in insertedFields) {
      if (newFields.length > indexField.index) {
        newFields.insert(indexField.index, indexField.field_1);
      } else {
        newFields.add(indexField.field_1);
      }
    }
    _fieldNotifier?.fields = newFields;
  }

  void _updateFields(List<GridFieldPB> updatedFields) {
    if (updatedFields.isEmpty) {
      return;
    }
    final List<GridFieldPB> newFields = fields;
    for (final updatedField in updatedFields) {
      final index =
          newFields.indexWhere((field) => field.id == updatedField.id);
      if (index != -1) {
        newFields.removeAt(index);
        newFields.insert(index, updatedField);
      }
    }
    _fieldNotifier?.fields = newFields;
  }
}

class GridRowFieldNotifierImpl extends IGridRowFieldNotifier {
  final GridFieldCache _cache;
  FieldChangesetCallback? _onChangesetFn;
  FieldsCallback? _onFieldFn;
  GridRowFieldNotifierImpl(GridFieldCache cache) : _cache = cache;

  @override
  UnmodifiableListView<GridFieldPB> get fields => _cache.unmodifiableFields;

  @override
  void onRowFieldsChanged(VoidCallback callback) {
    _onFieldFn = (_) => callback();
    _cache.addListener(onFields: _onFieldFn);
  }

  @override
  void onRowFieldChanged(void Function(GridFieldPB) callback) {
    _onChangesetFn = (GridFieldChangesetPB changeset) {
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

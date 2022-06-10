import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/field/grid_listenr.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/foundation.dart';
import 'cell/cell_service/cell_service.dart';
import 'row/row_service.dart';

class GridService {
  final String gridId;
  GridService({
    required this.gridId,
  });

  Future<Either<Grid, FlowyError>> loadGrid() async {
    await FolderEventSetLatestView(ViewId(value: gridId)).send();

    final payload = GridId(value: gridId);
    return GridEventGetGridData(payload).send();
  }

  Future<Either<Row, FlowyError>> createRow({Option<String>? startRowId}) {
    CreateRowPayload payload = CreateRowPayload.create()..gridId = gridId;
    startRowId?.fold(() => null, (id) => payload.startRowId = id);
    return GridEventCreateRow(payload).send();
  }

  Future<Either<RepeatedField, FlowyError>> getFields({required List<FieldOrder> fieldOrders}) {
    final payload = QueryFieldPayload.create()
      ..gridId = gridId
      ..fieldOrders = RepeatedFieldOrder(items: fieldOrders);
    return GridEventGetFields(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeGrid() {
    final request = ViewId(value: gridId);
    return FolderEventCloseView(request).send();
  }
}

class FieldsNotifier extends ChangeNotifier {
  List<Field> _fields = [];

  set fields(List<Field> fields) {
    _fields = fields;
    notifyListeners();
  }

  List<Field> get fields => _fields;
}

typedef ChangesetListener = void Function(GridFieldChangeset);

class GridFieldCache {
  final String gridId;
  late final GridFieldsListener _fieldListener;
  FieldsNotifier? _fieldNotifier = FieldsNotifier();
  final List<ChangesetListener> _changesetListener = [];

  GridFieldCache({required this.gridId}) {
    _fieldListener = GridFieldsListener(gridId: gridId);
    _fieldListener.start(onFieldsChanged: (result) {
      result.fold(
        (changeset) {
          _deleteFields(changeset.deletedFields);
          _insertFields(changeset.insertedFields);
          _updateFields(changeset.updatedFields);
          for (final listener in _changesetListener) {
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

  UnmodifiableListView<Field> get unmodifiableFields => UnmodifiableListView(_fieldNotifier?.fields ?? []);

  List<Field> get fields => [..._fieldNotifier?.fields ?? []];

  set fields(List<Field> fields) {
    _fieldNotifier?.fields = [...fields];
  }

  VoidCallback addListener(
      {VoidCallback? listener, void Function(List<Field>)? onChanged, bool Function()? listenWhen}) {
    f() {
      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      if (onChanged != null) {
        onChanged(fields);
      }

      if (listener != null) {
        listener();
      }
    }

    _fieldNotifier?.addListener(f);
    return f;
  }

  void removeListener(VoidCallback f) {
    _fieldNotifier?.removeListener(f);
  }

  void addChangesetListener(ChangesetListener listener) {
    _changesetListener.add(listener);
  }

  void removeChangesetListener(ChangesetListener listener) {
    final index = _changesetListener.indexWhere((element) => element == listener);
    if (index != -1) {
      _changesetListener.removeAt(index);
    }
  }

  void _deleteFields(List<FieldOrder> deletedFields) {
    if (deletedFields.isEmpty) {
      return;
    }
    final List<Field> newFields = fields;
    final Map<String, FieldOrder> deletedFieldMap = {
      for (var fieldOrder in deletedFields) fieldOrder.fieldId: fieldOrder
    };

    newFields.retainWhere((field) => (deletedFieldMap[field.id] == null));
    _fieldNotifier?.fields = newFields;
  }

  void _insertFields(List<IndexField> insertedFields) {
    if (insertedFields.isEmpty) {
      return;
    }
    final List<Field> newFields = fields;
    for (final indexField in insertedFields) {
      if (newFields.length > indexField.index) {
        newFields.insert(indexField.index, indexField.field_1);
      } else {
        newFields.add(indexField.field_1);
      }
    }
    _fieldNotifier?.fields = newFields;
  }

  void _updateFields(List<Field> updatedFields) {
    if (updatedFields.isEmpty) {
      return;
    }
    final List<Field> newFields = fields;
    for (final updatedField in updatedFields) {
      final index = newFields.indexWhere((field) => field.id == updatedField.id);
      if (index != -1) {
        newFields.removeAt(index);
        newFields.insert(index, updatedField);
      }
    }
    _fieldNotifier?.fields = newFields;
  }
}

class GridRowCacheDelegateImpl extends GridRowFieldDelegate {
  final GridFieldCache _cache;
  GridRowCacheDelegateImpl(GridFieldCache cache) : _cache = cache;

  @override
  UnmodifiableListView<Field> get fields => _cache.unmodifiableFields;

  @override
  void onFieldChanged(FieldDidUpdateCallback callback) {
    _cache.addListener(listener: () {
      callback();
    });
  }
}

class GridCellCacheDelegateImpl extends GridCellFieldDelegate {
  final GridFieldCache _cache;
  ChangesetListener? _changesetFn;
  GridCellCacheDelegateImpl(GridFieldCache cache) : _cache = cache;

  @override
  void onFieldChanged(void Function(String) callback) {
    changesetFn(GridFieldChangeset changeset) {
      for (final updatedField in changeset.updatedFields) {
        callback(updatedField.id);
      }
    }

    _cache.addChangesetListener(changesetFn);
    _changesetFn = changesetFn;
  }

  @override
  void dispose() {
    if (_changesetFn != null) {
      _cache.removeChangesetListener(_changesetFn!);
      _changesetFn = null;
    }
  }
}

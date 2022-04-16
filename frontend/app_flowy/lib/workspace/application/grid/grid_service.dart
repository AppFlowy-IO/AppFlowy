import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

class GridFieldCache {
  final FieldsNotifier _fieldNotifier = FieldsNotifier();
  GridFieldCache();

  void applyChangeset(GridFieldChangeset changeset) {
    _removeFields(changeset.deletedFields);
    _insertFields(changeset.insertedFields);
    _updateFields(changeset.updatedFields);
  }

  UnmodifiableListView<Field> get unmodifiableFields => UnmodifiableListView(_fieldNotifier.fields);

  List<Field> get clonedFields => [..._fieldNotifier.fields];

  set clonedFields(List<Field> fields) {
    _fieldNotifier.fields = [...fields];
  }

  void listenOnFieldChanged(void Function(List<Field>) onFieldChanged) {
    _fieldNotifier.addListener(() => onFieldChanged(clonedFields));
  }

  void addListener(VoidCallback listener, {void Function(List<Field>)? onChanged, bool Function()? listenWhen}) {
    _fieldNotifier.addListener(() {
      if (onChanged != null) {
        onChanged(clonedFields);
      }

      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      listener();
    });
  }

  void _removeFields(List<FieldOrder> deletedFields) {
    if (deletedFields.isEmpty) {
      return;
    }
    final List<Field> fields = _fieldNotifier.fields;
    final Map<String, FieldOrder> deletedFieldMap = {
      for (var fieldOrder in deletedFields) fieldOrder.fieldId: fieldOrder
    };

    fields.retainWhere((field) => (deletedFieldMap[field.id] == null));
    _fieldNotifier.fields = fields;
  }

  void _insertFields(List<IndexField> insertedFields) {
    if (insertedFields.isEmpty) {
      return;
    }
    final List<Field> fields = _fieldNotifier.fields;
    for (final indexField in insertedFields) {
      if (fields.length > indexField.index) {
        fields.insert(indexField.index, indexField.field_1);
      } else {
        fields.add(indexField.field_1);
      }
    }
    _fieldNotifier.fields = fields;
  }

  void _updateFields(List<Field> updatedFields) {
    if (updatedFields.isEmpty) {
      return;
    }
    final List<Field> fields = _fieldNotifier.fields;
    for (final updatedField in updatedFields) {
      final index = fields.indexWhere((field) => field.id == updatedField.id);
      if (index != -1) {
        fields.removeAt(index);
        fields.insert(index, updatedField);
      }
    }
    _fieldNotifier.fields = fields;
  }

  void dispose() {
    _fieldNotifier.dispose();
  }
}

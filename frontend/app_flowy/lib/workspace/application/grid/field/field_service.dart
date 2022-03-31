import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';

class FieldService {
  final String gridId;

  FieldService({required this.gridId});

  Future<Either<EditFieldContext, FlowyError>> getEditFieldContext(FieldType fieldType) {
    final payload = GetEditFieldContextParams.create()
      ..gridId = gridId
      ..fieldType = fieldType;

    return GridEventGetEditFieldContext(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateField({
    required String fieldId,
    String? name,
    FieldType? fieldType,
    bool? frozen,
    bool? visibility,
    double? width,
    List<int>? typeOptionData,
  }) {
    var payload = FieldChangesetPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId;

    if (name != null) {
      payload.name = name;
    }

    if (fieldType != null) {
      payload.fieldType = fieldType;
    }

    if (frozen != null) {
      payload.frozen = frozen;
    }

    if (visibility != null) {
      payload.visibility = visibility;
    }

    if (width != null) {
      payload.width = width.toInt();
    }

    if (typeOptionData != null) {
      payload.typeOptionData = typeOptionData;
    }

    return GridEventUpdateField(payload).send();
  }

  Future<Either<Unit, FlowyError>> createField({
    required Field field,
    List<int>? typeOptionData,
    String? startFieldId,
  }) {
    var payload = CreateFieldPayload.create()
      ..gridId = gridId
      ..field_2 = field
      ..typeOptionData = typeOptionData ?? [];

    if (startFieldId != null) {
      payload.startFieldId = startFieldId;
    }

    return GridEventCreateField(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteField({
    required String fieldId,
  }) {
    final payload = FieldIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId;

    return GridEventDeleteField(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateField({
    required String fieldId,
  }) {
    final payload = FieldIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId;

    return GridEventDuplicateField(payload).send();
  }
}

class GridFieldData extends Equatable {
  final String gridId;
  final Field field;

  const GridFieldData({
    required this.gridId,
    required this.field,
  });

  @override
  List<Object> get props => [field.id];
}

abstract class FieldContextLoader {
  Future<Either<EditFieldContext, FlowyError>> load();
}

class NewFieldContextLoader extends FieldContextLoader {
  final String gridId;
  NewFieldContextLoader({
    required this.gridId,
  });

  @override
  Future<Either<EditFieldContext, FlowyError>> load() {
    final payload = GetEditFieldContextParams.create()
      ..gridId = gridId
      ..fieldType = FieldType.RichText;

    return GridEventGetEditFieldContext(payload).send();
  }
}

class FieldContextLoaderAdaptor extends FieldContextLoader {
  final GridFieldData data;

  FieldContextLoaderAdaptor(this.data);

  @override
  Future<Either<EditFieldContext, FlowyError>> load() {
    final payload = GetEditFieldContextParams.create()
      ..gridId = data.gridId
      ..fieldId = data.field.id
      ..fieldType = data.field.fieldType;

    return GridEventGetEditFieldContext(payload).send();
  }
}

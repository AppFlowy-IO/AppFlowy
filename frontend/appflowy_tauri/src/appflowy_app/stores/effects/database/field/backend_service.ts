import {
  DeleteFieldPayloadPB,
  DuplicateFieldPayloadPB,
  FieldChangesetPB,
  FieldType,
  TypeOptionChangesetPB,
  TypeOptionPathPB,
} from '../../../../../services/backend/models/flowy-database/field_entities';
import {
  DatabaseEventDeleteField,
  DatabaseEventDuplicateField,
  DatabaseEventGetTypeOption,
  DatabaseEventUpdateField,
  DatabaseEventUpdateFieldTypeOption,
} from '../../../../../services/backend/events/flowy-database';
export class FieldBackendService {
  constructor(public readonly databaseId: string, public readonly fieldId: string) {}

  updateField = (data: {
    name?: string;
    fieldType: FieldType;
    frozen?: boolean;
    visibility?: boolean;
    width?: number;
  }) => {
    const payload = FieldChangesetPB.fromObject({ database_id: this.databaseId, field_id: this.fieldId });

    if (data.name !== undefined) {
      payload.name = data.name;
    }

    if (data.fieldType !== undefined) {
      payload.field_type = data.fieldType;
    }

    if (data.frozen !== undefined) {
      payload.frozen = data.frozen;
    }

    if (data.visibility !== undefined) {
      payload.visibility = data.visibility;
    }

    if (data.width !== undefined) {
      payload.width = data.width;
    }

    return DatabaseEventUpdateField(payload);
  };

  updateTypeOption = (typeOptionData: Uint8Array) => {
    const payload = TypeOptionChangesetPB.fromObject({
      database_id: this.databaseId,
      field_id: this.fieldId,
      type_option_data: typeOptionData,
    });

    return DatabaseEventUpdateFieldTypeOption(payload);
  };

  deleteField = () => {
    const payload = DeleteFieldPayloadPB.fromObject({ database_id: this.databaseId, field_id: this.fieldId });

    return DatabaseEventDeleteField(payload);
  };

  duplicateField = () => {
    const payload = DuplicateFieldPayloadPB.fromObject({ database_id: this.databaseId, field_id: this.fieldId });

    return DatabaseEventDuplicateField(payload);
  };

  getTypeOptionData = (fieldType: FieldType) => {
    const payload = TypeOptionPathPB.fromObject({
      database_id: this.databaseId,
      field_id: this.fieldId,
      field_type: fieldType,
    });

    return DatabaseEventGetTypeOption(payload);
  };
}

import {
  DeleteFieldPayloadPB,
  DuplicateFieldPayloadPB,
  FieldChangesetPB,
  FieldType,
  TypeOptionChangesetPB,
  TypeOptionPathPB,
} from '@/services/backend';
import {
  DatabaseEventDeleteField,
  DatabaseEventDuplicateField,
  DatabaseEventGetTypeOption,
  DatabaseEventUpdateField,
  DatabaseEventUpdateFieldTypeOption,
} from '@/services/backend/events/flowy-database2';

export abstract class TypeOptionParser<T> {
  abstract fromBuffer(buffer: Uint8Array): T;
}

export class FieldBackendService {
  constructor(public readonly viewId: string, public readonly fieldId: string) {}

  updateField = (data: { name?: string; frozen?: boolean; visibility?: boolean; width?: number }) => {
    const payload = FieldChangesetPB.fromObject({ view_id: this.viewId, field_id: this.fieldId });

    if (data.name !== undefined) {
      payload.name = data.name;
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
      view_id: this.viewId,
      field_id: this.fieldId,
      type_option_data: typeOptionData,
    });

    return DatabaseEventUpdateFieldTypeOption(payload);
  };

  deleteField = () => {
    const payload = DeleteFieldPayloadPB.fromObject({ view_id: this.viewId, field_id: this.fieldId });
    return DatabaseEventDeleteField(payload);
  };

  duplicateField = () => {
    const payload = DuplicateFieldPayloadPB.fromObject({ view_id: this.viewId, field_id: this.fieldId });
    return DatabaseEventDuplicateField(payload);
  };

  getTypeOptionData = (fieldType: FieldType) => {
    const payload = TypeOptionPathPB.fromObject({
      view_id: this.viewId,
      field_id: this.fieldId,
      field_type: fieldType,
    });

    return DatabaseEventGetTypeOption(payload);
  };
}

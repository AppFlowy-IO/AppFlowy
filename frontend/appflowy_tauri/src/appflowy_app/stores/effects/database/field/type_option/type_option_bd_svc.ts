import {
  CreateFieldPayloadPB,
  FieldType,
  TypeOptionPathPB,
  UpdateFieldTypePayloadPB,
} from '@/services/backend';
import {
  DatabaseEventCreateTypeOption,
  DatabaseEventGetTypeOption,
  DatabaseEventUpdateFieldType,
} from '@/services/backend/events/flowy-database';

export class TypeOptionBackendService {
  constructor(public readonly viewId: string) {}

  createTypeOption = (fieldType: FieldType) => {
    const payload = CreateFieldPayloadPB.fromObject({ view_id: this.viewId, field_type: fieldType });
    return DatabaseEventCreateTypeOption(payload);
  };

  getTypeOption = (fieldId: string, fieldType: FieldType) => {
    const payload = TypeOptionPathPB.fromObject({
      view_id: this.viewId,
      field_id: fieldId,
      field_type: fieldType,
    });
    return DatabaseEventGetTypeOption(payload);
  };

  updateTypeOptionType = (fieldId: string, fieldType: FieldType) => {
    const payload = UpdateFieldTypePayloadPB.fromObject({
      view_id: this.viewId,
      field_id: fieldId,
      field_type: fieldType,
    });
    return DatabaseEventUpdateFieldType(payload);
  };
}

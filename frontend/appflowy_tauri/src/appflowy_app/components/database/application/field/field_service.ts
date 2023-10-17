import {
  CreateFieldPayloadPB,
  DeleteFieldPayloadPB,
  DuplicateFieldPayloadPB,
  FieldChangesetPB,
  FieldType,
  GetFieldPayloadPB,
  MoveFieldPayloadPB,
  RepeatedFieldIdPB,
  UpdateFieldTypePayloadPB,
} from '@/services/backend';
import {
  DatabaseEventDuplicateField,
  DatabaseEventUpdateField,
  DatabaseEventUpdateFieldType,
  DatabaseEventMoveField,
  DatabaseEventGetFields,
  DatabaseEventDeleteField,
  DatabaseEventCreateTypeOption,
} from '@/services/backend/events/flowy-database2';
import { Field, pbToField } from './field_types';
import { bytesToTypeOption, getTypeOption } from './type_option';

export async function getFields(viewId: string, fieldIds?: string[]): Promise<Field[]> {
  const payload = GetFieldPayloadPB.fromObject({
    view_id: viewId,
    field_ids: fieldIds ? RepeatedFieldIdPB.fromObject({
      items: fieldIds.map(fieldId => ({ field_id: fieldId })),
    }) : undefined,
  });

  const result = await DatabaseEventGetFields(payload);

  const fields = result.map((value) => value.items.map(pbToField)).unwrap();

  await Promise.all(fields.map(async field => {
    const typeOption = await getTypeOption(viewId, field.id, field.type);

    field.typeOption = typeOption;
  }));

  return fields;
}

export async function createField(viewId: string, fieldType?: FieldType, data?: Uint8Array): Promise<Field> {
  const payload = CreateFieldPayloadPB.fromObject({
    view_id: viewId,
    field_type: fieldType,
    type_option_data: data,
  });

  const result = await DatabaseEventCreateTypeOption(payload);

  return result.map(value => {
    const field = pbToField(value.field);

    field.typeOption = bytesToTypeOption(value.type_option_data, field.type);

    return field;
  }).unwrap();
}

export async function duplicateField(viewId: string, fieldId: string): Promise<void> {
  const payload = DuplicateFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
  });

  const result = await DatabaseEventDuplicateField(payload);

  return result.unwrap();
}

export async function updateField(viewId: string, fieldId: string, data: {
  name?: string;
  desc?: string;
  frozen?: boolean;
  visibility?: boolean;
  width?: number;
}): Promise<void> {
  const payload = FieldChangesetPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    ...data,
  });

  const result = await DatabaseEventUpdateField(payload);

  return result.unwrap();
}

export async function updateFieldType(viewId: string, fieldId: string, fieldType: FieldType): Promise<void> {
  const payload = UpdateFieldTypePayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    field_type: fieldType,
  });

  const result = await DatabaseEventUpdateFieldType(payload);

  return result.unwrap();
}

export async function moveField(viewId: string, fieldId: string, fromIndex: number, toIndex: number): Promise<void> {
  const payload = MoveFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    from_index: fromIndex,
    to_index: toIndex,
  });

  const result = await DatabaseEventMoveField(payload);

  return result.unwrap();
}

export async function deleteField(viewId: string, fieldId: string): Promise<void> {
  const payload = DeleteFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
  });

  const result = await DatabaseEventDeleteField(payload);

  return result.unwrap();
}

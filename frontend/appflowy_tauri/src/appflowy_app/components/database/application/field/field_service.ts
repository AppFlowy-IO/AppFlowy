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
  FieldSettingsChangesetPB,
  FieldVisibility,
  DatabaseViewIdPB,
} from '@/services/backend';
import {
  DatabaseEventDuplicateField,
  DatabaseEventUpdateField,
  DatabaseEventUpdateFieldType,
  DatabaseEventMoveField,
  DatabaseEventGetFields,
  DatabaseEventDeleteField,
  DatabaseEventCreateField,
  DatabaseEventUpdateFieldSettings,
  DatabaseEventGetAllFieldSettings,
} from '@/services/backend/events/flowy-database2';
import { Field, pbToField } from './field_types';
import { bytesToTypeOption, getTypeOption } from './type_option';

export async function getFields(viewId: string, fieldIds?: string[]): Promise<Field[]> {
  const payload = GetFieldPayloadPB.fromObject({
    view_id: viewId,
    field_ids: fieldIds
      ? RepeatedFieldIdPB.fromObject({
          items: fieldIds.map((fieldId) => ({ field_id: fieldId })),
        })
      : undefined,
  });

  const result = await DatabaseEventGetFields(payload);

  const getSettingsPayload = DatabaseViewIdPB.fromObject({
    value: viewId,
  });

  const settings = await DatabaseEventGetAllFieldSettings(getSettingsPayload);

  if (settings.ok === false || result.ok === false) {
    return Promise.reject('Failed to get fields');
  }

  const fields = await Promise.all(
    result.val.items.map(async (item) => {
      const setting = settings.val.items.find((setting) => setting.field_id === item.id);
      const field = pbToField(item);
      const typeOption = await getTypeOption(viewId, field.id, field.type);

      return {
        ...field,
        visibility: setting?.visibility,
        width: setting?.width,
        typeOption,
      };
    })
  );

  return fields;
}

export async function createField(viewId: string, fieldType?: FieldType, data?: Uint8Array): Promise<Field> {
  const payload = CreateFieldPayloadPB.fromObject({
    view_id: viewId,
    field_type: fieldType,
    type_option_data: data,
  });

  const result = await DatabaseEventCreateField(payload);

  if (result.ok === false) {
    return Promise.reject('Failed to create field');
  }

  const field = pbToField(result.val.field);

  field.typeOption = bytesToTypeOption(result.val.type_option_data, field.type);
  return field;
}

export async function duplicateField(viewId: string, fieldId: string): Promise<void> {
  const payload = DuplicateFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
  });

  const result = await DatabaseEventDuplicateField(payload);

  if (result.ok === false) {
    return Promise.reject('Failed to duplicate field');
  }

  return result.val;
}

export async function updateField(
  viewId: string,
  fieldId: string,
  data: {
    name?: string;
    desc?: string;
  }
): Promise<void> {
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

export async function updateFieldSetting(
  viewId: string,
  fieldId: string,
  settings: {
    visibility?: FieldVisibility;
    width?: number;
  }
): Promise<void> {
  const payload = FieldSettingsChangesetPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    ...settings,
  });

  const result = await DatabaseEventUpdateFieldSettings(payload);

  if (result.ok === false) {
    return Promise.reject('Failed to update field settings');
  }

  return result.val;
}

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
  CreateFieldPosition,
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
import { getTypeOption } from './type_option';
import { Database } from '$app/components/database/application';

export async function getFields(
  viewId: string,
  fieldIds?: string[]
): Promise<{
  fields: Field[];
  typeOptions: Database['typeOptions'];
}> {
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

  const typeOptions: Database['typeOptions'] = {};

  const fields = await Promise.all(
    result.val.items.map(async (item) => {
      const setting = settings.val.items.find((setting) => setting.field_id === item.id);

      const field = pbToField(item);

      const typeOption = await getTypeOption(viewId, item.id, item.field_type);

      if (typeOption) {
        typeOptions[item.id] = typeOption;
      }

      return {
        ...field,
        visibility: setting?.visibility,
        width: setting?.width,
      };
    })
  );

  return { fields, typeOptions };
}

export async function createField({
  viewId,
  targetFieldId,
  fieldPosition,
  fieldType,
  data,
}: {
  viewId: string;
  targetFieldId?: string;
  fieldPosition?: CreateFieldPosition;
  fieldType?: FieldType;
  data?: Uint8Array;
}): Promise<Field> {
  const payload = CreateFieldPayloadPB.fromObject({
    view_id: viewId,
    field_type: fieldType,
    type_option_data: data,
    target_field_id: targetFieldId,
    field_position: fieldPosition,
  });

  const result = await DatabaseEventCreateField(payload);

  if (result.ok === false) {
    return Promise.reject('Failed to create field');
  }

  return pbToField(result.val.field);
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

export const reorderFields = (list: Field[], startIndex: number, endIndex: number) => {
  const result = Array.from(list);
  const [removed] = result.splice(startIndex, 1);

  result.splice(endIndex, 0, removed);

  return result;
};

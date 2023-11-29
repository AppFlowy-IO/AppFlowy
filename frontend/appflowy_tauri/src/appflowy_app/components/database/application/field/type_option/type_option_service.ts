import { FieldType, TypeOptionPathPB, TypeOptionChangesetPB } from '@/services/backend';
import {
  DatabaseEventGetTypeOption,
  DatabaseEventUpdateFieldTypeOption,
} from '@/services/backend/events/flowy-database2';
import { bytesToTypeOption, UndeterminedTypeOptionData, typeOptionDataToPB } from './type_option_types';

export async function getTypeOption(viewId: string, fieldId: string, fieldType: FieldType) {
  const payload = TypeOptionPathPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    field_type: fieldType,
  });

  const result = await DatabaseEventGetTypeOption(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  const value = result.val;

  return bytesToTypeOption(value.type_option_data, fieldType);
}

export async function updateTypeOption(
  viewId: string,
  fieldId: string,
  fieldType: FieldType,
  data: UndeterminedTypeOptionData
) {
  const payload = TypeOptionChangesetPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    type_option_data: typeOptionDataToPB(data, fieldType)?.serialize(),
  });

  const result = await DatabaseEventUpdateFieldTypeOption(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  return;
}

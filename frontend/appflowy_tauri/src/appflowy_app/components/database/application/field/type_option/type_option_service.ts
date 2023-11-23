import { CreateFieldPayloadPB, FieldType, TypeOptionPathPB } from '@/services/backend';
import { DatabaseEventCreateTypeOption, DatabaseEventGetTypeOption } from '@/services/backend/events/flowy-database2';
import { bytesToTypeOption } from './type_option_types';

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

export async function createTypeOption(viewId: string, fieldType: FieldType, data?: Uint8Array) {
  const payload = CreateFieldPayloadPB.fromObject({
    view_id: viewId,
    field_type: fieldType,
    type_option_data: data,
  });

  const result = await DatabaseEventCreateTypeOption(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  const value = result.val;

  return bytesToTypeOption(value.type_option_data, fieldType);
}

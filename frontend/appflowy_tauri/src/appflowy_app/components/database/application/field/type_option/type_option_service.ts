import {
  FieldType,
  TypeOptionPathPB,
} from '@/services/backend';
import { DatabaseEventGetTypeOption } from '@/services/backend/events/flowy-database2';
import { bytesToTypeOption } from './type_option_types';

export async function getTypeOption(viewId: string, fieldId: string, fieldType: FieldType) {
  const payload = TypeOptionPathPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    field_type: fieldType,
  });

  const result = await DatabaseEventGetTypeOption(payload);

  return result.map(value => bytesToTypeOption(value.type_option_data, fieldType)).unwrap();
}

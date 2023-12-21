import { FieldType, TypeOptionChangesetPB } from '@/services/backend';
import {
  DatabaseEventUpdateFieldTypeOption,
} from '@/services/backend/events/flowy-database2';
import { UndeterminedTypeOptionData, typeOptionDataToPB } from './type_option_types';

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

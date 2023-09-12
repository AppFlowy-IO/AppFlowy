import { t } from 'i18next';
import { FieldType } from '@/services/backend';

export const FieldTypeTextMap = {
  [FieldType.RichText]: 'textFieldName',
  [FieldType.Number]: 'numberFieldName',
  [FieldType.DateTime]: 'dateFieldName',
  [FieldType.SingleSelect]: 'singleSelectFieldName',
  [FieldType.MultiSelect]: 'multiSelectFieldName',
  [FieldType.Checkbox]: 'checkboxFieldName',
  [FieldType.URL]: 'urlFieldName',
  [FieldType.Checklist]: 'checklistFieldName',
  [FieldType.LastEditedTime]: 'updatedAtFieldName',
  [FieldType.CreatedTime]: 'createdAtFieldName',
} as const;

export const FieldTypeText = (type: FieldType) => {
  return t(`grid.field.${FieldTypeTextMap[type]}`);
}
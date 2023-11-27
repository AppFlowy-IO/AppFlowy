import {
  CheckboxFilterConditionPB,
  ChecklistFilterConditionPB,
  FieldType,
  NumberFilterConditionPB,
  TextFilterConditionPB,
} from '@/services/backend';
import { UndeterminedFilter } from '$app/components/database/application';

export function getDefaultFilter(fieldType: FieldType): UndeterminedFilter['data'] | undefined {
  switch (fieldType) {
    case FieldType.RichText:
    case FieldType.URL:
      return {
        condition: TextFilterConditionPB.Contains,
        content: '',
      };
    case FieldType.Number:
      return {
        condition: NumberFilterConditionPB.NumberIsNotEmpty,
      };
    case FieldType.Checkbox:
      return {
        condition: CheckboxFilterConditionPB.IsUnChecked,
      };
    case FieldType.Checklist:
      return {
        condition: ChecklistFilterConditionPB.IsIncomplete,
      };
    default:
      return;
  }
}

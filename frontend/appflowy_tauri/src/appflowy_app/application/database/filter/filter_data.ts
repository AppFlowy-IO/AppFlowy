import {
  CheckboxFilterConditionPB,
  ChecklistFilterConditionPB,
  FieldType,
  NumberFilterConditionPB,
  SelectOptionConditionPB,
  TextFilterConditionPB,
} from '@/services/backend';
import { UndeterminedFilter } from '$app/application/database';

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
    case FieldType.SingleSelect:
      return {
        condition: SelectOptionConditionPB.OptionIs,
      };
    case FieldType.MultiSelect:
      return {
        condition: SelectOptionConditionPB.OptionContains,
      };
    default:
      return;
  }
}

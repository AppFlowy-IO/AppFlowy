import {
  CheckboxFilterConditionPB,
  ChecklistFilterConditionPB,
  FieldType,
  NumberFilterConditionPB,
  SelectOptionFilterConditionPB,
  TextFilterConditionPB,
} from '@/services/backend';
import { UndeterminedFilter } from '$app/application/database';

export function getDefaultFilter(fieldType: FieldType): UndeterminedFilter['data'] | undefined {
  switch (fieldType) {
    case FieldType.RichText:
    case FieldType.URL:
      return {
        condition: TextFilterConditionPB.TextContains,
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
        condition: SelectOptionFilterConditionPB.OptionIs,
      };
    case FieldType.MultiSelect:
      return {
        condition: SelectOptionFilterConditionPB.OptionContains,
      };
    default:
      return;
  }
}

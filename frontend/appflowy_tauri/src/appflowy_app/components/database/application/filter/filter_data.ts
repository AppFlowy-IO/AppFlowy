import { TextFilterConditionPB, FieldType, SelectOptionConditionPB } from '@/services/backend';
import { UndeterminedFilter } from '$app/components/database/application';

export function getDefaultFilter(fieldType: FieldType): UndeterminedFilter['data'] | undefined {
  switch (fieldType) {
    case FieldType.RichText:
      return {
        condition: TextFilterConditionPB.Contains,
        content: '',
      };
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return {
        condition: SelectOptionConditionPB.OptionIs,
        optionIds: [],
      };
    default:
      return;
  }
}

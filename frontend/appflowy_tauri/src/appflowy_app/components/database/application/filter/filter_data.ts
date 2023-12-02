import { TextFilterConditionPB, FieldType } from '@/services/backend';
import { UndeterminedFilter } from '$app/components/database/application';

export function getDefaultFilter(fieldType: FieldType): UndeterminedFilter['data'] | undefined {
  switch (fieldType) {
    case FieldType.RichText:
      return {
        condition: TextFilterConditionPB.Contains,
        content: '',
      };
    default:
      return;
  }
}

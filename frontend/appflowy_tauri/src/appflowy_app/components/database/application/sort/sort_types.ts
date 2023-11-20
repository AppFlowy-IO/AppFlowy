import { FieldType, SortConditionPB, SortPB } from '@/services/backend';

export interface Sort {
  id: string;
  fieldId: string;
  fieldType: FieldType;
  condition: SortConditionPB;
}

export function pbToSort(pb: SortPB): Sort {
  return {
    id: pb.id,
    fieldId: pb.field_id,
    fieldType: pb.field_type,
    condition: pb.condition,
  };
}

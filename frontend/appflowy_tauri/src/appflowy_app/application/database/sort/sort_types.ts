import { SortConditionPB, SortPB } from '@/services/backend';

export interface Sort {
  id: string;
  fieldId: string;
  condition: SortConditionPB;
}

export function pbToSort(pb: SortPB): Sort {
  return {
    id: pb.id,
    fieldId: pb.field_id,
    condition: pb.condition,
  };
}

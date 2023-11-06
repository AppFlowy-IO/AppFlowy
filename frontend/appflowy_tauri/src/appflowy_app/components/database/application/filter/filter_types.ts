import {
  FieldType,
  TextFilterConditionPB,
  SelectOptionConditionPB,
  TextFilterPB,
  SelectOptionFilterPB,
  FilterPB,
} from '@/services/backend';

export interface Filter {
  id: string;
  fieldId: string;
  fieldType: FieldType;
  data: unknown;
}

export interface TextFilter extends Filter {
  fieldType: FieldType.RichText;
  data: TextFilterData;
}

export interface TextFilterData {
  condition: TextFilterConditionPB;
  content?: string;
}

export interface SelectFilter extends Filter {
  fieldType: FieldType.SingleSelect | FieldType.MultiSelect;
  data: SelectFilterData;
}

export interface SelectFilterData {
  condition?: SelectOptionConditionPB;
  optionIds?: string[];
}

export type UndeterminedFilter = TextFilter | SelectFilter;

export function filterDataToPB(data: UndeterminedFilter['data'], fieldType: FieldType) {
  switch (fieldType) {
    case FieldType.RichText:
      return TextFilterPB.fromObject({
        condition: (data as TextFilterData).condition,
        content: (data as TextFilterData).content,
      });
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return SelectOptionFilterPB.fromObject({
        condition: (data as SelectFilterData).condition,
        option_ids: (data as SelectFilterData).optionIds,
      });
  }
}

export function pbToTextFilterData(pb: TextFilterPB): TextFilterData {
  return {
    condition: pb.condition,
    content: pb.content,
  };
}

export function pbToSelectFilterData(pb: SelectOptionFilterPB): SelectFilterData {
  return {
    condition: pb.condition,
    optionIds: pb.option_ids,
  };
}

export function bytesToFilterData(bytes: Uint8Array, fieldType: FieldType) {
  switch (fieldType) {
    case FieldType.RichText:
      return pbToTextFilterData(TextFilterPB.deserialize(bytes));
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return pbToSelectFilterData(SelectOptionFilterPB.deserialize(bytes));
  }
}

export function pbToFilter(pb: FilterPB): Filter {
  return {
    id: pb.id,
    fieldId: pb.field_id,
    fieldType: pb.field_type,
    data: bytesToFilterData(pb.data, pb.field_type),
  };
}

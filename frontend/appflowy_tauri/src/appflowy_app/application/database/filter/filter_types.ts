import {
  CheckboxFilterConditionPB,
  CheckboxFilterPB,
  FieldType,
  FilterPB,
  NumberFilterConditionPB,
  NumberFilterPB,
  SelectOptionConditionPB,
  SelectOptionFilterPB,
  TextFilterConditionPB,
  TextFilterPB,
  ChecklistFilterConditionPB,
  ChecklistFilterPB,
  DateFilterConditionPB,
  DateFilterPB,
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

export interface NumberFilter extends Filter {
  fieldType: FieldType.Number;
  data: NumberFilterData;
}

export interface CheckboxFilter extends Filter {
  fieldType: FieldType.Checkbox;
  data: CheckboxFilterData;
}

export interface CheckboxFilterData {
  condition?: CheckboxFilterConditionPB;
}

export interface ChecklistFilter extends Filter {
  fieldType: FieldType.Checklist;
  data: ChecklistFilterData;
}

export interface DateFilter extends Filter {
  fieldType: FieldType.DateTime | FieldType.CreatedTime | FieldType.LastEditedTime;
  data: DateFilterData;
}

export interface ChecklistFilterData {
  condition?: ChecklistFilterConditionPB;
}

export interface SelectFilterData {
  condition?: SelectOptionConditionPB;
  optionIds?: string[];
}

export interface NumberFilterData {
  condition: NumberFilterConditionPB;
  content?: string;
}

export interface DateFilterData {
  condition: DateFilterConditionPB;
  start?: number;
  end?: number;
  timestamp?: number;
}

export type UndeterminedFilter =
  | TextFilter
  | SelectFilter
  | NumberFilter
  | CheckboxFilter
  | ChecklistFilter
  | DateFilter;

export function filterDataToPB(data: UndeterminedFilter['data'], fieldType: FieldType) {
  switch (fieldType) {
    case FieldType.RichText:
    case FieldType.URL:
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
    case FieldType.Number:
      return NumberFilterPB.fromObject({
        condition: (data as NumberFilterData).condition,
        content: (data as NumberFilterData).content,
      });
    case FieldType.Checkbox:
      return CheckboxFilterPB.fromObject({
        condition: (data as CheckboxFilterData).condition,
      });
    case FieldType.Checklist:
      return ChecklistFilterPB.fromObject({
        condition: (data as ChecklistFilterData).condition,
      });
    case FieldType.DateTime:
    case FieldType.CreatedTime:
    case FieldType.LastEditedTime:
      return DateFilterPB.fromObject({
        condition: (data as DateFilterData).condition,
        start: (data as DateFilterData).start,
        end: (data as DateFilterData).end,
        timestamp: (data as DateFilterData).timestamp,
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

export function pbToNumberFilterData(pb: NumberFilterPB): NumberFilterData {
  return {
    condition: pb.condition,
    content: pb.content,
  };
}

export function pbToCheckboxFilterData(pb: CheckboxFilterPB): CheckboxFilterData {
  return {
    condition: pb.condition,
  };
}

export function pbToChecklistFilterData(pb: ChecklistFilterPB): ChecklistFilterData {
  return {
    condition: pb.condition,
  };
}

export function pbToDateFilterData(pb: DateFilterPB): DateFilterData {
  return {
    condition: pb.condition,
    start: pb.start,
    end: pb.end,
    timestamp: pb.timestamp,
  };
}

export function bytesToFilterData(bytes: Uint8Array, fieldType: FieldType) {
  switch (fieldType) {
    case FieldType.RichText:
    case FieldType.URL:
      return pbToTextFilterData(TextFilterPB.deserialize(bytes));
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return pbToSelectFilterData(SelectOptionFilterPB.deserialize(bytes));
    case FieldType.Number:
      return pbToNumberFilterData(NumberFilterPB.deserialize(bytes));
    case FieldType.Checkbox:
      return pbToCheckboxFilterData(CheckboxFilterPB.deserialize(bytes));
    case FieldType.Checklist:
      return pbToChecklistFilterData(ChecklistFilterPB.deserialize(bytes));
    case FieldType.DateTime:
    case FieldType.CreatedTime:
    case FieldType.LastEditedTime:
      return pbToDateFilterData(DateFilterPB.deserialize(bytes));
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

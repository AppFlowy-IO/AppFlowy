import {
  CheckboxTypeOptionPB,
  DateFormatPB,
  FieldType,
  MultiSelectTypeOptionPB,
  NumberFormatPB,
  NumberTypeOptionPB,
  RichTextTypeOptionPB,
  SingleSelectTypeOptionPB,
  TimeFormatPB,
  ChecklistTypeOptionPB,
} from '@/services/backend';
import { pbToSelectOption, SelectOption } from '../select_option';

export interface TextTypeOption {
  data?: string;
}

export interface NumberTypeOption {
  format?: NumberFormatPB;
  scale?: number;
  symbol?: string;
  name?: string;
}

export interface DateTimeTypeOption {
  dateFormat?: DateFormatPB;
  timeFormat?: TimeFormatPB;
  timezoneId?: string;
  fieldType?: FieldType;
}

export interface SelectTypeOption {
  options?: SelectOption[];
  disableColor?: boolean;
}

export interface CheckboxTypeOption {
  isSelected?: boolean;
}

export interface ChecklistTypeOption {
  config?: string;
}

export type UndeterminedTypeOptionData =
  | TextTypeOption
  | NumberTypeOption
  | SelectTypeOption
  | CheckboxTypeOption
  | ChecklistTypeOption;

export function typeOptionDataToPB(data: UndeterminedTypeOptionData, fieldType: FieldType) {
  switch (fieldType) {
    case FieldType.Number:
      return NumberTypeOptionPB.fromObject(data as NumberTypeOption);
    default:
      return null;
  }
}

function pbToSelectTypeOption(pb: SingleSelectTypeOptionPB | MultiSelectTypeOptionPB): SelectTypeOption {
  return {
    options: pb.options?.map(pbToSelectOption),
    disableColor: pb.disable_color,
  };
}

function pbToCheckboxTypeOption(pb: CheckboxTypeOptionPB): CheckboxTypeOption {
  return {
    isSelected: pb.is_selected,
  };
}

function pbToChecklistTypeOption(pb: ChecklistTypeOptionPB): ChecklistTypeOption {
  return {
    config: pb.config,
  };
}

export function bytesToTypeOption(data: Uint8Array, fieldType: FieldType) {
  switch (fieldType) {
    case FieldType.RichText:
      return RichTextTypeOptionPB.deserialize(data).toObject() as TextTypeOption;
    case FieldType.Number:
      return NumberTypeOptionPB.deserialize(data).toObject() as NumberTypeOption;
    case FieldType.SingleSelect:
      return pbToSelectTypeOption(SingleSelectTypeOptionPB.deserialize(data));
    case FieldType.MultiSelect:
      return pbToSelectTypeOption(MultiSelectTypeOptionPB.deserialize(data));
    case FieldType.Checkbox:
      return pbToCheckboxTypeOption(CheckboxTypeOptionPB.deserialize(data));
    case FieldType.Checklist:
      return pbToChecklistTypeOption(ChecklistTypeOptionPB.deserialize(data));
  }
}

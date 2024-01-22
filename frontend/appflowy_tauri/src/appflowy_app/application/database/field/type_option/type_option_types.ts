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
  DateTypeOptionPB,
  TimestampTypeOptionPB,
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
}
export interface TimeStampTypeOption extends DateTimeTypeOption {
  includeTime?: boolean;
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
  | ChecklistTypeOption
  | DateTimeTypeOption
  | TimeStampTypeOption;

export function typeOptionDataToPB(data: UndeterminedTypeOptionData, fieldType: FieldType) {
  switch (fieldType) {
    case FieldType.Number:
      return NumberTypeOptionPB.fromObject(data as NumberTypeOption);
    case FieldType.DateTime:
      return dateTimeTypeOptionToPB(data as DateTimeTypeOption);
    case FieldType.CreatedTime:
    case FieldType.LastEditedTime:
      return timestampTypeOptionToPB(data as TimeStampTypeOption);

    default:
      return null;
  }
}

function dateTimeTypeOptionToPB(data: DateTimeTypeOption): DateTypeOptionPB {
  return DateTypeOptionPB.fromObject({
    time_format: data.timeFormat,
    date_format: data.dateFormat,
    timezone_id: data.timezoneId,
  });
}

function timestampTypeOptionToPB(data: TimeStampTypeOption): TimestampTypeOptionPB {
  return TimestampTypeOptionPB.fromObject({
    include_time: data.includeTime,
    date_format: data.dateFormat,
    time_format: data.timeFormat,
    field_type: data.fieldType,
  });
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

function pbToDateTypeOption(pb: DateTypeOptionPB): DateTimeTypeOption {
  return {
    dateFormat: pb.date_format,
    timezoneId: pb.timezone_id,
    timeFormat: pb.time_format,
  };
}

function pbToTimeStampTypeOption(pb: TimestampTypeOptionPB): TimeStampTypeOption {
  return {
    includeTime: pb.include_time,
    dateFormat: pb.date_format,
    timeFormat: pb.time_format,
    fieldType: pb.field_type,
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
    case FieldType.DateTime:
      return pbToDateTypeOption(DateTypeOptionPB.deserialize(data));
    case FieldType.CreatedTime:
    case FieldType.LastEditedTime:
      return pbToTimeStampTypeOption(TimestampTypeOptionPB.deserialize(data));
  }
}

import {
  CellPB,
  ChecklistCellDataPB,
  DateCellDataPB,
  FieldType,
  SelectOptionCellDataPB,
  TimestampCellDataPB,
  URLCellDataPB,
} from '@/services/backend';
import {
  SelectOption,
  pbToSelectOption,
} from '$app/components/database/application/field/select_option/select_option_types';

export interface Cell {
  rowId: string;
  fieldId: string;
  fieldType: FieldType;
  data: unknown;
}

export interface TextCell extends Cell {
  fieldType: FieldType.RichText;
  data: string;
}

export interface NumberCell extends Cell {
  fieldType: FieldType.Number;
  data: string;
}

export interface CheckboxCell extends Cell {
  fieldType: FieldType.Checkbox;
  data: 'Yes' | 'No';
}

export interface UrlCell extends Cell {
  fieldType: FieldType.URL;
  data: UrlCellData;
}

export interface UrlCellData {
  url: string;
  content?: string;
}

export interface SelectCell extends Cell {
  fieldType: FieldType.SingleSelect | FieldType.MultiSelect;
  data: SelectCellData;
}

export interface SelectCellData {
  selectedOptionIds?: string[];
}

export interface DateTimeCell extends Cell {
  fieldType: FieldType.DateTime;
  data: DateTimeCellData;
}

export interface TimeStampCell extends Cell {
  fieldType: FieldType.LastEditedTime | FieldType.CreatedTime;
  data: TimestampCellData;
}

export interface DateTimeCellData {
  date?: string;
  time?: string;
  timestamp?: number;
  includeTime?: boolean;
  endDate?: string;
  endTime?: string;
  endTimestamp?: number;
  isRange?: boolean;
}

export interface TimestampCellData {
  dataTime?: string;
  timestamp?: number;
}

export interface ChecklistCell extends Cell {
  fieldType: FieldType.Checklist;
  data: ChecklistCellData;
}

export interface ChecklistCellData {
  /**
   * link to [SelectOption's id property]{@link SelectOption#id}.
   */
  selectedOptions?: string[];
  percentage?: number;
  options?: SelectOption[];
}

export type UndeterminedCell =
  | TextCell
  | NumberCell
  | DateTimeCell
  | SelectCell
  | CheckboxCell
  | UrlCell
  | ChecklistCell;

const pbToDateTimeCellData = (pb: DateCellDataPB): DateTimeCellData => ({
  date: pb.date,
  time: pb.time,
  timestamp: pb.timestamp,
  includeTime: pb.include_time,
  endDate: pb.end_date,
  endTime: pb.end_time,
  endTimestamp: pb.end_timestamp,
  isRange: pb.is_range,
});

const pbToTimestampCellData = (pb: TimestampCellDataPB): TimestampCellData => ({
  dataTime: pb.date_time,
  timestamp: pb.timestamp,
});

export const pbToSelectCellData = (pb: SelectOptionCellDataPB): SelectCellData => {
  return {
    selectedOptionIds: pb.select_options.map((option) => option.id),
  };
};

const pbToURLCellData = (pb: URLCellDataPB): UrlCellData => ({
  url: pb.url,
  content: pb.content,
});

export const pbToChecklistCellData = (pb: ChecklistCellDataPB): ChecklistCellData => ({
  selectedOptions: pb.selected_options.map(({ id }) => id),
  percentage: pb.percentage,
  options: pb.options.map(pbToSelectOption),
});

function bytesToCellData(bytes: Uint8Array, fieldType: FieldType) {
  switch (fieldType) {
    case FieldType.RichText:
    case FieldType.Number:
    case FieldType.Checkbox:
      return new TextDecoder().decode(bytes);
    case FieldType.DateTime:
      return pbToDateTimeCellData(DateCellDataPB.deserialize(bytes));
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return pbToTimestampCellData(TimestampCellDataPB.deserialize(bytes));
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return pbToSelectCellData(SelectOptionCellDataPB.deserialize(bytes));
    case FieldType.URL:
      return pbToURLCellData(URLCellDataPB.deserialize(bytes));
    case FieldType.Checklist:
      return pbToChecklistCellData(ChecklistCellDataPB.deserialize(bytes));
  }
}

export const pbToCell = (pb: CellPB, fieldType: FieldType = pb.field_type): Cell => {
  return {
    rowId: pb.row_id,
    fieldId: pb.field_id,
    fieldType: fieldType,
    data: bytesToCellData(pb.data, fieldType),
  };
};

import { RowId } from '@/application/collab.type';
import { DateFormat, SelectOption, TimeFormat } from '@/application/database-yjs';
import { FieldType } from '@/application/database-yjs/database.type';
import { YArray } from 'yjs/dist/src/types/YArray';

export interface Cell {
  createdAt: number;
  lastModified: number;
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
  data: boolean;
}

export interface UrlCell extends Cell {
  fieldType: FieldType.URL;
  data: string;
}

export type SelectionId = string;

export interface SelectCell extends Cell {
  fieldType: FieldType.SingleSelect | FieldType.MultiSelect;
  data: SelectionId;
}

export interface DataTimeTypeOption {
  timeFormat: TimeFormat;
  dateFormat: DateFormat;
}

export interface DateTimeCell extends Cell {
  fieldType: FieldType.DateTime;
  data: string;
  endTimestamp?: string;
  includeTime?: boolean;
  isRange?: boolean;
  reminderId?: string;
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
  data: string;
}

export interface RelationCell extends Cell {
  fieldType: FieldType.Relation;
  data: YArray<unknown>;
}

export type RelationCellData = RowId[];

export interface ChecklistCellData {
  selected_option_ids?: string[];
  options?: SelectOption[];
}

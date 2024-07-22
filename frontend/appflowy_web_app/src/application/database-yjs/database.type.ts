import { FieldId } from '@/application/collab.type';

export enum FieldVisibility {
  AlwaysShown = 0,
  HideWhenEmpty = 1,
  AlwaysHidden = 2,
}

export enum FieldType {
  RichText = 0,
  Number = 1,
  DateTime = 2,
  SingleSelect = 3,
  MultiSelect = 4,
  Checkbox = 5,
  URL = 6,
  Checklist = 7,
  LastEditedTime = 8,
  CreatedTime = 9,
  Relation = 10,
  AISummaries = 11,
  AITranslations = 12,
}

export enum CalculationType {
  Average = 0,
  Max = 1,
  Median = 2,
  Min = 3,
  Sum = 4,
  Count = 5,
  CountEmpty = 6,
  CountNonEmpty = 7,
}

export enum SortCondition {
  Ascending = 0,
  Descending = 1,
}

export enum FilterType {
  Data = 0,
  And = 1,
  Or = 2,
}

export interface Filter {
  fieldId: FieldId;
  filterType: FilterType;
  condition: number;
  id: string;
  content: string;
}

export enum CalendarLayout {
  MonthLayout = 0,
  WeekLayout = 1,
  DayLayout = 2,
}

export interface CalendarLayoutSetting {
  fieldId: string;
  firstDayOfWeek: number;
  showWeekNumbers: boolean;
  showWeekends: boolean;
  layout: CalendarLayout;
}

export enum RowMetaKey {
  DocumentId = 'document_id',
  IconId = 'icon_id',
  CoverId = 'cover_id',
  IsDocumentEmpty = 'is_document_empty',
}

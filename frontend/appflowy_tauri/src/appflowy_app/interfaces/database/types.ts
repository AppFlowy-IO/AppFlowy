import {
  CalendarLayoutPB,
  DatabaseLayoutPB,
  DateFormatPB,
  FieldType,
  NumberFormatPB,
  SelectOptionColorPB,
  SelectOptionConditionPB,
  SortConditionPB,
  TextFilterConditionPB,
  TimeFormatPB,
} from '@/services/backend';


export interface Database {
  id: string;
  viewId: string;
  name: string;
  fields: Database.UndeterminedField[];
  rows: Database.Row[];
  layoutType: DatabaseLayoutPB;
  layoutSetting: Database.GridLayoutSetting | Database.CalendarLayoutSetting;
  isLinked: boolean;
}

// eslint-disable-next-line @typescript-eslint/no-namespace, no-redeclare
export namespace Database {

  export interface GridLayoutSetting {
    filters?: UndeterminedFilter[];
    groups?: Group[];
    sorts?: Sort[];
  }
  
  export interface CalendarLayoutSetting {
    fieldId?: string;
    layoutTy?: CalendarLayoutPB;
    firstDayOfWeek?: number;
    showWeekends?: boolean;
    showWeekNumbers?: boolean;
  }

  export interface Field {
    id: string;
    name: string;
    type: FieldType;
    typeOption?: unknown;
    visibility?: boolean;
    width?: number;
    isPrimary?: boolean;
  }
  
  export interface NumberTypeOption {
    format?: NumberFormatPB;
    scale?: number;
    symbol?: string;
    name?: string;
  }

  export interface NumberField extends Field {
    type: FieldType.Number;
    typeOption: NumberTypeOption;
  }
  
  export interface DateTimeTypeOption {
    dateFormat?: DateFormatPB;
    timeFormat?: TimeFormatPB;
    timezoneId?: string;
    fieldType?: FieldType;
  }

  export interface DateTimeField extends Field {
    type: FieldType.DateTime;
    typeOption: DateTimeTypeOption;
  }
  
  export interface SelectOption {
    id: string;
    name: string;
    color: SelectOptionColorPB;
  }
  
  export interface SelectTypeOption {
    options?: SelectOption[];
    disableColor?: boolean;
  }

  export interface SelectField extends Field {
    type: FieldType.SingleSelect | FieldType.MultiSelect;
    typeOption: SelectTypeOption;
  }
  
  export interface ChecklistTypeOption {
    config?: string;
  }

  export interface ChecklistField extends Field {
    type: FieldType.Checklist;
    typeOption: ChecklistTypeOption;
  }

  export type UndeterminedField = NumberField | DateTimeField | SelectField | ChecklistField | Field;
  
  export interface Sort {
    id: string;
    fieldId: string;
    fieldType: FieldType;
    condition: SortConditionPB;
  }
  
  export interface Group {
    id: string;
    fieldId: string;
  }
  
  export interface Filter {
    id: string;
    fieldId: string;
    fieldType: FieldType;
    data: unknown;
  }

  export interface TextFilter extends Filter {
    fieldType: FieldType.RichText;
    data: TextFilterCondition;
  }
  
  export interface TextFilterCondition {
    condition?: TextFilterConditionPB;
    content?: string;
  }

  export interface SelectFilter extends Filter {
    fieldType: FieldType.SingleSelect | FieldType.MultiSelect;
    data: SelectFilterCondition;
  }
  
  export interface SelectFilterCondition {
    condition?: SelectOptionConditionPB;
    /**
     * link to [SelectOption's id property]{@link SelectOption#id}.
     */
    optionIds?: string[];
  }

  export type UndeterminedFilter = TextFilter | SelectFilter | Filter;

  export interface Row {
    id: string;
    documentId?: string;
    icon?: string;
    cover?: string;
    createdAt?: number;
    modifiedAt?: number;  
    height?: number;
    visibility?: boolean;
  }
  
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
    options?: SelectOption[];
    selectOptions?: SelectOption[];
  }
  
  export interface DateTimeCell extends Cell {
    fieldType: FieldType.DateTime;
    data: DateTimeCellData;
  }

  export interface DateTimeCellData {
    date?: string;
    time?: string;
    timestamp?: number;
    includeTime?: boolean;
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
  }

  export type UndeterminedCell = TextCell | NumberCell | DateTimeCell | SelectCell | CheckboxCell | UrlCell | ChecklistCell;
}

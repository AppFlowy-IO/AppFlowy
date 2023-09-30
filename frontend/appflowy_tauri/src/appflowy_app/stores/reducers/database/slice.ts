import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { FieldType } from '@/services/backend/models/flowy-database2/field_entities';
import { DateFormatPB, NumberFormatPB, SelectOptionColorPB, SortConditionPB, TimeFormatPB } from '@/services/backend';

export interface ISelectOption {
  selectOptionId: string;
  title: string;
  color: SelectOptionColorPB;
}

export interface ISelectOptionType {
  selectOptions: ISelectOption[];
}

export interface IDateType {
  dateFormat: DateFormatPB;
  timeFormat: TimeFormatPB;
  // includeTime: boolean;
}

export interface INumberType {
  numberFormat: NumberFormatPB;
}

export interface IDatabaseField {
  fieldId: string;
  title: string;
  visible: boolean;
  width: number;
  fieldType: FieldType;
  fieldOptions?: ISelectOptionType | IDateType | INumberType;
}

export interface IDatabaseColumn {
  fieldId: string;
  sort: 'none' | 'asc' | 'desc';
  visible: boolean;
}

export interface IDatabaseRow {
  rowId: string;
}

export type DatabaseFieldMap = { [keys: string]: IDatabaseField };

export type TDatabaseOperators =
  | 'contains'
  | 'doesNotContain'
  | 'endsWith'
  | 'startWith'
  | 'is'
  | 'isNot'
  | 'isEmpty'
  | 'isNotEmpty'
  | 'isComplete'
  | 'isIncomplted';

export type TSupportedOperatorsByType = { [keys: number]: TDatabaseOperators[] };

export const SupportedOperatorsByType: TSupportedOperatorsByType = {
  [FieldType.RichText]: ['contains', 'doesNotContain', 'endsWith', 'startWith', 'is', 'isNot', 'isEmpty', 'isNotEmpty'],
  [FieldType.SingleSelect]: ['is', 'isNot', 'isEmpty', 'isNotEmpty'],
  [FieldType.MultiSelect]: ['contains', 'doesNotContain', 'isEmpty', 'isNotEmpty'],
  [FieldType.Checkbox]: ['is'],
  [FieldType.Checklist]: ['isComplete', 'isIncomplted'],
};

export interface IDatabaseFilter {
  id?: string;
  fieldId: string;
  fieldType: FieldType;
  logicalOperator: 'and' | 'or';
  operator: TDatabaseOperators;
  value: string[] | string | boolean;
}

export interface IDatabaseSort {
  id?: string;
  fieldId: string;
  fieldType: FieldType;
  order: SortConditionPB;
}

export interface IDatabase {
  title: string;
  fields: DatabaseFieldMap;
  rows: IDatabaseRow[];
  columns: IDatabaseColumn[];
  filters: IDatabaseFilter[];
  sort: IDatabaseSort[];
}

const initialState: IDatabase = {
  title: 'Database One',
  columns: [],
  fields: {},
  rows: [],
  filters: [],
  sort: [],
};

export const databaseSlice = createSlice({
  name: 'database',
  initialState: initialState,
  reducers: {
    clear: () => {
      return initialState;
    },

    updateRows: (state, action: PayloadAction<{ rows: IDatabaseRow[] }>) => {
      return {
        ...state,
        rows: action.payload.rows,
      };
    },

    updateFields: (state, action: PayloadAction<{ fields: DatabaseFieldMap }>) => {
      return {
        ...state,
        fields: action.payload.fields,
      };
    },

    updateColumns: (state, action: PayloadAction<{ columns: IDatabaseColumn[] }>) => {
      return {
        ...state,
        columns: action.payload.columns,
      };
    },

    updateTitle: (state, action: PayloadAction<{ title: string }>) => {
      state.title = action.payload.title;
    },

    updateField: (state, action: PayloadAction<{ field: IDatabaseField }>) => {
      const { field } = action.payload;

      state.fields[field.fieldId] = field;
    },

    changeWidth: (state, action: PayloadAction<{ fieldId: string; width: number }>) => {
      const { fieldId, width } = action.payload;

      state.fields[fieldId].width = width;
    },

    updateFilters: (state, action: PayloadAction<{ filters: IDatabaseFilter[] }>) => {
      state.filters = action.payload.filters;
    },

    updateSorts: (state, action: PayloadAction<{ sorts: IDatabaseSort[] }>) => {
      state.sort = action.payload.sorts;
    },
  },
});

export const databaseActions = databaseSlice.actions;

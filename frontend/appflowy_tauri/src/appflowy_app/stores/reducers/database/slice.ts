import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { FieldType } from '@/services/backend/models/flowy-database2/field_entities';
import { DateFormatPB, NumberFormatPB, SelectOptionColorPB, TimeFormatPB } from '@/services/backend';

export interface ISelectOption {
  selectOptionId: string;
  title: string;
  color?: SelectOptionColorPB;
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

export interface IDatabase {
  title: string;
  fields: DatabaseFieldMap;
  rows: IDatabaseRow[];
  columns: IDatabaseColumn[];
}

const initialState: IDatabase = {
  title: 'Database One',
  columns: [],
  fields: {},
  rows: [],
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

    /*addField: (state, action: PayloadAction<{ field: IDatabaseField }>) => {
      const { field } = action.payload;

      state.fields[field.fieldId] = field;
      state.columns.push({
        fieldId: field.fieldId,
        sort: 'none',
        visible: true,
      });
      state.rows = state.rows.map<IDatabaseRow>((r: IDatabaseRow) => {
        const cells = r.cells;
        cells[field.fieldId] = {
          rowId: r.rowId,
          fieldId: field.fieldId,
          data: [''],
          cellId: nanoid(6),
        };
        return {
          rowId: r.rowId,
          cells: cells,
        };
      });
    },*/

    updateField: (state, action: PayloadAction<{ field: IDatabaseField }>) => {
      const { field } = action.payload;
      state.fields[field.fieldId] = field;
    },

    /*addFieldSelectOption: (state, action: PayloadAction<{ fieldId: string; option: ISelectOption }>) => {
      const { fieldId, option } = action.payload;

      const field = state.fields[fieldId];
      const selectOptions = field.fieldOptions?.selectOptions;

      if (selectOptions) {
        selectOptions.push(option);
      } else {
        state.fields[field.fieldId].fieldOptions = {
          ...state.fields[field.fieldId].fieldOptions,
          selectOptions: [option],
        };
      }
    },*/

    /*updateFieldSelectOption: (state, action: PayloadAction<{ fieldId: string; option: ISelectOption }>) => {
      const { fieldId, option } = action.payload;

      const field = state.fields[fieldId];
      const selectOptions = field.fieldOptions?.selectOptions;
      if (selectOptions) {
        selectOptions[selectOptions.findIndex((o) => o.selectOptionId === option.selectOptionId)] = option;
      }
    },*/

    /*addRow: (state) => {
      const rowId = nanoid(6);
      const cells: { [keys: string]: ICellData } = {};
      Object.keys(state.fields).forEach((id) => {
        cells[id] = {
          rowId: rowId,
          fieldId: id,
          data: [''],
          cellId: nanoid(6),
        };
      });
      const newRow: IDatabaseRow = {
        rowId: rowId,
        cells: cells,
      };

      state.rows.push(newRow);
    },*/

    /*updateCellValue: (source, action: PayloadAction<{ cell: ICellData }>) => {
      const { cell } = action.payload;
      const row = source.rows.find((r) => r.rowId === cell.rowId);
      if (row) {
        row.cells[cell.fieldId] = cell;
      }
    },*/
  },
});

export const databaseActions = databaseSlice.actions;

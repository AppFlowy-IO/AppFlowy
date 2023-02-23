import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { nanoid } from 'nanoid';
import { FieldType } from '../../../../services/backend/models/flowy-database/field_entities';
import { DateFormat, NumberFormat, SelectOptionColorPB, TimeFormat } from '../../../../services/backend';

export interface ISelectOption {
  selectOptionId: string;
  title: string;
  color?: SelectOptionColorPB;
}

export interface IFieldOptions {
  selectOptions?: ISelectOption[];
  dateFormat?: DateFormat;
  timeFormat?: TimeFormat;
  includeTime?: boolean;
  numberFormat?: NumberFormat;
}

export interface IDatabaseField {
  fieldId: string;
  title: string;
  fieldType: FieldType;
  fieldOptions: IFieldOptions;
}

export interface IDatabaseColumn {
  fieldId: string;
  sort: 'none' | 'asc' | 'desc';
  filter?: any;
  visible: boolean;
}

export interface ICellData {
  rowId: string;
  fieldId: string;
  cellId: string;
  data: string | number;
  optionIds?: string[];
}

export type DatabaseCellMap = { [keys: string]: ICellData };

export interface IDatabaseRow {
  rowId: string;
  // key(fieldId) -> value(Cell)
  cells: DatabaseCellMap;
}

export type DatabaseFieldMap = { [keys: string]: IDatabaseField };

export interface IDatabase {
  title: string;
  fields: DatabaseFieldMap;
  rows: IDatabaseRow[];
  columns: IDatabaseColumn[];
}

// key(databaseId) -> value(IDatabase)
const initialState: { [keys: string]: IDatabase } = {
  testDb: {
    title: 'Database One',
    columns: [
      {
        visible: true,
        fieldId: 'field1',
        sort: 'none',
      },
      {
        visible: true,
        fieldId: 'field2',
        sort: 'none',
      },
      {
        visible: true,
        fieldId: 'field3',
        sort: 'none',
      },
      {
        visible: true,
        fieldId: 'field4',
        sort: 'none',
      },
    ],
    fields: {
      field1: {
        title: 'status',
        fieldId: 'field1',
        fieldType: FieldType.SingleSelect,
        fieldOptions: {
          selectOptions: [
            {
              selectOptionId: 'so1',
              title: 'To Do',
              color: SelectOptionColorPB.Orange,
            },
            {
              selectOptionId: 'so2',
              title: 'In Progress',
              color: SelectOptionColorPB.Green,
            },
            {
              selectOptionId: 'so3',
              title: 'Done',
              color: SelectOptionColorPB.Blue,
            },
          ],
        },
      },
      field2: {
        title: 'name',
        fieldId: 'field2',
        fieldType: FieldType.RichText,
        fieldOptions: {},
      },
      field3: {
        title: 'percent',
        fieldId: 'field3',
        fieldType: FieldType.Number,
        fieldOptions: {
          numberFormat: NumberFormat.Num,
        },
      },
      field4: {
        title: 'tags',
        fieldId: 'field4',
        fieldType: FieldType.MultiSelect,
        fieldOptions: {
          selectOptions: [
            {
              selectOptionId: 'f4so1',
              title: 'type1',
              color: SelectOptionColorPB.Blue,
            },
            {
              selectOptionId: 'f4so2',
              title: 'type2',
              color: SelectOptionColorPB.Aqua,
            },
            {
              selectOptionId: 'f4so3',
              title: 'type3',
              color: SelectOptionColorPB.Purple,
            },
            {
              selectOptionId: 'f4so4',
              title: 'type4',
              color: SelectOptionColorPB.Purple,
            },
            {
              selectOptionId: 'f4so5',
              title: 'type5',
              color: SelectOptionColorPB.Purple,
            },
            {
              selectOptionId: 'f4so6',
              title: 'type6',
              color: SelectOptionColorPB.Purple,
            },
            {
              selectOptionId: 'f4so7',
              title: 'type7',
              color: SelectOptionColorPB.Purple,
            },
          ],
        },
      },
    },
    rows: [
      {
        rowId: 'row1',
        cells: {
          field1: {
            rowId: 'row1',
            fieldId: 'field1',
            cellId: 'cell11',
            data: '',
            optionIds: ['so1'],
          },
          field2: {
            rowId: 'row1',
            fieldId: 'field2',
            cellId: 'cell12',
            data: 'Card 1',
          },
          field3: {
            rowId: 'row1',
            fieldId: 'field3',
            cellId: 'cell13',
            data: 10,
          },
          field4: {
            rowId: 'row1',
            fieldId: 'field4',
            cellId: 'cell14',
            data: '',
            optionIds: ['f4so2', 'f4so3', 'f4so4', 'f4so5', 'f4so6', 'f4so7'],
          },
        },
      },
      {
        rowId: 'row2',
        cells: {
          field1: {
            rowId: 'row2',
            fieldId: 'field1',
            cellId: 'cell21',
            data: '',
            optionIds: ['so1'],
          },
          field2: {
            rowId: 'row2',
            fieldId: 'field2',
            cellId: 'cell22',
            data: 'Card 2',
          },
          field3: {
            rowId: 'row2',
            fieldId: 'field3',
            cellId: 'cell23',
            data: 20,
          },
          field4: {
            rowId: 'row2',
            fieldId: 'field4',
            cellId: 'cell24',
            data: '',
            optionIds: ['f4so1'],
          },
        },
      },
    ],
  },
};

export const databaseSlice = createSlice({
  name: 'database',
  initialState: initialState,
  reducers: {
    updateTitle: (state, action: PayloadAction<{ databaseId: string; title: string }>) => {
      state[action.payload.databaseId].title = action.payload.title;
    },

    addField: (state, action: PayloadAction<{ databaseId: string; field: IDatabaseField }>) => {
      const { databaseId, field } = action.payload;
      const source = state[databaseId];
      if (!source) return;

      source.fields[field.fieldId] = field;
      source.columns.push({
        fieldId: field.fieldId,
        sort: 'none',
        visible: true,
      });
      source.rows = source.rows.map<IDatabaseRow>((r: IDatabaseRow) => {
        const cells = r.cells;
        cells[field.fieldId] = {
          rowId: r.rowId,
          fieldId: field.fieldId,
          data: '',
          cellId: nanoid(6),
        };
        return {
          rowId: r.rowId,
          cells: cells,
        };
      });
    },

    updateField: (state, action: PayloadAction<{ databaseId: string; field: IDatabaseField }>) => {
      const { databaseId, field } = action.payload;
      const source = state[databaseId];

      source.fields[field.fieldId] = field;
    },

    addFieldSelectOption: (
      state,
      action: PayloadAction<{ databaseId: string; fieldId: string; option: ISelectOption }>
    ) => {
      const { databaseId, fieldId, option } = action.payload;

      const source = state[databaseId];
      const field = source.fields[fieldId];
      const selectOptions = field.fieldOptions?.selectOptions;

      if (selectOptions) {
        selectOptions.push(option);
      } else {
        source.fields[field.fieldId].fieldOptions = {
          ...source.fields[field.fieldId].fieldOptions,
          selectOptions: [option],
        };
      }
    },

    updateFieldSelectOption: (
      state,
      action: PayloadAction<{ databaseId: string; fieldId: string; option: ISelectOption }>
    ) => {
      const { databaseId, fieldId, option } = action.payload;

      const source = state[databaseId];
      const field = source.fields[fieldId];
      const selectOptions = field.fieldOptions?.selectOptions;
      if (selectOptions) {
        selectOptions[selectOptions.findIndex((o) => o.selectOptionId === option.selectOptionId)] = option;
      }
    },

    addRow: (state, action: PayloadAction<{ databaseId: string }>) => {
      const rowId = nanoid(6);
      const cells: { [keys: string]: ICellData } = {};
      Object.keys(state.fields).forEach((id) => {
        cells[id] = {
          rowId: rowId,
          fieldId: id,
          data: '',
          cellId: nanoid(6),
        };
      });
      const newRow: IDatabaseRow = {
        rowId: rowId,
        cells: cells,
      };

      state[action.payload.databaseId].rows.push(newRow);
    },

    updateCellValue: (state, action: PayloadAction<{ databaseId: string; cell: ICellData }>) => {
      const { databaseId, cell } = action.payload;
      const source = state[databaseId];
      const row = source.rows.find((r) => r.rowId === cell.rowId);
      if (row) {
        row.cells[cell.fieldId] = cell;
      }
    },
  },
});

export const databaseActions = databaseSlice.actions;

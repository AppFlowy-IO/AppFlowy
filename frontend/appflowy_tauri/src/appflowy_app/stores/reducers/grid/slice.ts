import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { nanoid } from 'nanoid';
import { FieldType } from '@/services/backend/models/flowy-database/field_entities';

const initialState = {
  title: 'My plans on the week',
  fields: [
    {
      fieldId: '1',
      fieldType: FieldType.RichText,
      fieldOptions: {},
      name: 'Todo',
    },
    {
      fieldId: '2',
      fieldType: FieldType.SingleSelect,
      fieldOptions: [],
      name: 'Status',
    },
    {
      fieldId: '3',
      fieldType: FieldType.Number,
      fieldOptions: [],
      name: 'Progress',
    },
    {
      fieldId: '4',
      fieldType: FieldType.DateTime,
      fieldOptions: [],
      name: 'Due Date',
    },
  ],
  rows: [
    {
      rowId: '1',
      values: [
        {
          fieldId: '1',
          value: 'Name 1',
          cellId: '1',
        },
        {
          fieldId: '2',
          value: 'Status 1',
          cellId: '2',
        },
        {
          fieldId: '3',
          value: 30,
          cellId: '3',
        },
        {
          fieldId: '4',
          value: 'tomorrow',
          cellId: '4',
        },
      ],
    },
    {
      rowId: '2',
      values: [
        {
          fieldId: '1',
          value: 'Name 2',
          cellId: '5',
        },
        {
          fieldId: '2',
          value: 'Status 2',
          cellId: '6',
        },
        {
          fieldId: '3',
          value: 40,
          cellId: '7',
        },
        {
          fieldId: '4',
          value: 'tomorrow',
          cellId: '8',
        },
      ],
    },
  ],
};

export type field = {
  fieldId: string;
  fieldType: FieldType;
  fieldOptions: any;
  name: string;
};

export const gridSlice = createSlice({
  name: 'grid',
  initialState: initialState,
  reducers: {
    updateGridTitle: (state, action: PayloadAction<{ title: string }>) => {
      state.title = action.payload.title;
    },

    addField: (state, action: PayloadAction<{ field: field }>) => {
      state.fields.push(action.payload.field);

      state.rows.map((row) => {
        row.values.push({
          fieldId: action.payload.field.fieldId,
          value: '',
          cellId: nanoid(),
        });
      });
    },

    addRow: (state) => {
      const newRow = {
        rowId: nanoid(),
        values: state.fields.map((f) => ({
          fieldId: f.fieldId,
          value: '',
          cellId: nanoid(),
        })),
      };

      state.rows.push(newRow);
    },

    updateRowValue: (state, action: PayloadAction<{ rowId: string; cellId: string; value: string | number }>) => {
      console.log('updateRowValue', action.payload);
      const row = state.rows.find((r) => r.rowId === action.payload.rowId);

      if (row) {
        const cell = row.values.find((c) => c.cellId === action.payload.cellId);
        if (cell) {
          cell.value = action.payload.value;
        }
      }
    },
  },
});

export const gridActions = gridSlice.actions;

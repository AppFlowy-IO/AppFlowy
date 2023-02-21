import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface IBoardGroupingFields {
  [keys: string]: string;
}

const initialState: IBoardGroupingFields = { uXRpVxvxIF: 'field1' };

export const boardSlice = createSlice({
  name: 'board',
  initialState: initialState,
  reducers: {
    setGroupingFieldId: (state, action: PayloadAction<{ databaseId: string; fieldId: string }>) => {
      state[action.payload.databaseId] = action.payload.fieldId;
    },
  },
});

export const boardActions = boardSlice.actions;

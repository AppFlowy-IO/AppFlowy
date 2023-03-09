import { createSlice, PayloadAction } from '@reduxjs/toolkit';

const initialState = '';

export const boardSlice = createSlice({
  name: 'board',
  initialState: initialState as string,
  reducers: {
    setGroupingFieldId: (state, action: PayloadAction<{ fieldId: string }>) => {
      return action.payload.fieldId;
    },
  },
});

export const boardActions = boardSlice.actions;

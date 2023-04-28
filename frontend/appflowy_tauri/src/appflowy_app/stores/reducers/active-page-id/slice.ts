import { createSlice, PayloadAction } from '@reduxjs/toolkit';
export const activePageIdSlice = createSlice({
  name: 'activePageId',
  initialState: '',
  reducers: {
    setActivePageId(state, action: PayloadAction<string>) {
      return action.payload;
    },
  },
});

export const activePageIdActions = activePageIdSlice.actions;

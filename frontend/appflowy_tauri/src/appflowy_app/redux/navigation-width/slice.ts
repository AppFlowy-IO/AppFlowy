import { createSlice, PayloadAction } from '@reduxjs/toolkit';

const initialState = 225;

export const navigationWidthSlice = createSlice({
  name: 'navigationWidth',
  initialState: initialState,
  reducers: {
    changeWidth(state, action: PayloadAction<number>) {
      return action.payload;
    },
  },
});

export const navigationWidthActions = navigationWidthSlice.actions;

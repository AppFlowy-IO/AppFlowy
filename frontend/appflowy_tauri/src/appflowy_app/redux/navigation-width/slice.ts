import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export const NAVIGATION_MIN_WIDTH = 200;

const initialState = 250;

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

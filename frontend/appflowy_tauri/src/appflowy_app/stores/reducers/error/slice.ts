import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface IErrorOptions {
  display: boolean;
  message: string;
}

const initialState: IErrorOptions = {
  display: false,
  message: '',
};

export const errorSlice = createSlice({
  name: 'error',
  initialState: initialState,
  reducers: {
    showError(state, action: PayloadAction<string>) {
      return {
        display: true,
        message: action.payload,
      };
    },
    hideError() {
      return {
        display: false,
        message: '',
      };
    },
  },
});

export const errorActions = errorSlice.actions;

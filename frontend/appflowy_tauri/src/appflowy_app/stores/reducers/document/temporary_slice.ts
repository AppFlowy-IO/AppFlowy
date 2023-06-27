import { TemporaryState } from '$app/interfaces/document';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { TEMPORARY_NAME } from '$app/constants/document/name';

const initialState: Record<string, TemporaryState> = {};

export const temporarySlice = createSlice({
  name: TEMPORARY_NAME,
  initialState,
  reducers: {
    setTemporaryState: (state, action: PayloadAction<{ id: string; state: TemporaryState }>) => {
      const { id, state: temporaryState } = action.payload;

      state[id] = temporaryState;
    },
    updateTemporaryState: (state, action: PayloadAction<{ id: string; state: Partial<TemporaryState> }>) => {
      const { id, state: temporaryState } = action.payload;

      if (!state[id]) {
        return;
      }

      if (temporaryState.id !== state[id].id) {
        return;
      }

      state[id] = { ...state[id], ...temporaryState };
    },
    deleteTemporaryState: (state, action: PayloadAction<string>) => {
      const id = action.payload;

      delete state[id];
    },
  },
});

export const temporaryActions = temporarySlice.actions;

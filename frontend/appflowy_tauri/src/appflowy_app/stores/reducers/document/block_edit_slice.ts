import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { BLOCK_EDIT_NAME } from '$app/constants/document/name';

interface BlockEditState {
  id: string;
  editing: boolean;
}

const initialState: Record<string, BlockEditState> = {};

export const blockEditSlice = createSlice({
  name: BLOCK_EDIT_NAME,
  initialState,
  reducers: {
    setBlockEditState: (state, action: PayloadAction<{ id: string; state: BlockEditState }>) => {
      const { id, state: blockEditState } = action.payload;

      state[id] = blockEditState;
    },
    initBlockEditState: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      state[docId] = {
        ...state[docId],
        editing: false,
      };
    },
  },
});

export const blockEditActions = blockEditSlice.actions;

import { MENTION_NAME } from '$app/constants/document/name';
import { createSlice } from '@reduxjs/toolkit';

export interface MentionState {
  open: boolean;
  blockId: string;
}
const initialState: Record<string, MentionState> = {};

export const mentionSlice = createSlice({
  name: MENTION_NAME,
  initialState,
  reducers: {
    open: (
      state,
      action: {
        payload: {
          docId: string;
          blockId: string;
        };
      }
    ) => {
      const { docId, blockId } = action.payload;

      state[docId] = {
        open: true,
        blockId,
      };
    },
    close: (state, action: { payload: { docId: string } }) => {
      const { docId } = action.payload;

      delete state[docId];
    },
  },
});

export const mentionActions = mentionSlice.actions;

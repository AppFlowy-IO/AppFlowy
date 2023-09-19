import { createAsyncThunk } from '@reduxjs/toolkit';
import { rangeActions } from '$app_reducers/document/slice';

export const setCursorRangeThunk = createAsyncThunk(
  'document/setCursorRange',
  async (payload: { docId: string; blockId: string; index: number; length?: number }, thunkAPI) => {
    const { blockId, index, docId, length = 0 } = payload;
    const { dispatch } = thunkAPI;

    dispatch(rangeActions.initialState(docId));
    dispatch(
      rangeActions.setCaret({
        docId,
        caret: {
          id: blockId,
          index,
          length,
        },
      })
    );
  }
);

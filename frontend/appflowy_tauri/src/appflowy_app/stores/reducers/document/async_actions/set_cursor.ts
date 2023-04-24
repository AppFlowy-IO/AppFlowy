import { DocumentController } from '@/appflowy_app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions, DocumentState, SelectionPoint, TextSelection } from '../slice';

export const setCursorBeforeThunk = createAsyncThunk(
  'document/setCursorBefore',
  async (payload: { id: string }, thunkAPI) => {
    const { id } = payload;
    const { dispatch } = thunkAPI;
    const selection: TextSelection = {
      anchor: {
        path: [0, 0],
        offset: 0,
      },
      focus: {
        path: [0, 0],
        offset: 0,
      },
    };
    dispatch(documentActions.setTextSelection({ blockId: id, selection }));
  }
);

export const setCursorAfterThunk = createAsyncThunk(
  'document/setCursorAfter',
  async (payload: { id: string }, thunkAPI) => {
    const { id } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const len = node.data.delta?.length || 0;
    const offset = len > 0 ? node.data.delta[len - 1].insert.length : 0;
    const cursorPoint: SelectionPoint = {
      path: [0, len > 0 ? len - 1 : 0],
      offset,
    };
    const selection: TextSelection = {
      anchor: {
        ...cursorPoint,
      },
      focus: {
        ...cursorPoint,
      },
    };
    dispatch(documentActions.setTextSelection({ blockId: node.id, selection }));
  }
);

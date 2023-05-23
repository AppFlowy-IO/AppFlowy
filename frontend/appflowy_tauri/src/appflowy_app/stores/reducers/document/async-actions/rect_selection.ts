import { createAsyncThunk } from '@reduxjs/toolkit';
import { getNextNodeId, getPrevNodeId } from '$app/utils/document/block';
import { DocumentState } from '$app/interfaces/document';
import { rectSelectionActions } from '$app_reducers/document/slice';

export const setRectSelectionThunk = createAsyncThunk(
  'document/setRectSelection',
  async (payload: string[], thunkAPI) => {
    const { getState, dispatch } = thunkAPI;
    const documentState = (getState() as { document: DocumentState }).document;
    const selected: Record<string, boolean> = {};
    payload.forEach((id) => {
      const node = documentState.nodes[id];
      if (!node.parent) {
        return;
      }
      selected[id] = selected[id] === undefined ? true : selected[id];
      selected[node.parent] = false;
      const nextNodeId = getNextNodeId(documentState, node.parent);
      const prevNodeId = getPrevNodeId(documentState, node.parent);
      if ((nextNodeId && payload.includes(nextNodeId)) || (prevNodeId && payload.includes(prevNodeId))) {
        selected[node.parent] = true;
      }
    });
    dispatch(rectSelectionActions.updateSelections(payload.filter((id) => selected[id])));
  }
);

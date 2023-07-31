import { createAsyncThunk } from '@reduxjs/toolkit';
import { getNextNodeId, getPrevNodeId } from '$app/utils/document/block';
import { rangeActions, rectSelectionActions } from '$app_reducers/document/slice';
import { RootState } from '$app/stores/store';

export const setRectSelectionThunk = createAsyncThunk(
  'document/setRectSelection',
  async (
    payload: {
      docId: string;
      selection: string[];
    },
    thunkAPI
  ) => {
    const { getState, dispatch } = thunkAPI;
    const { docId, selection } = payload;
    const documentState = (getState() as RootState).document[docId];
    const selected: Record<string, boolean> = {};

    selection.forEach((id) => {
      const node = documentState.nodes[id];

      if (!node.parent) {
        return;
      }

      selected[id] = selected[id] === undefined ? true : selected[id];
      selected[node.parent] = false;
      const nextNodeId = getNextNodeId(documentState, node.parent);
      const prevNodeId = getPrevNodeId(documentState, node.parent);

      if ((nextNodeId && selection.includes(nextNodeId)) || (prevNodeId && selection.includes(prevNodeId))) {
        selected[node.parent] = true;
      }
    });
    dispatch(rangeActions.initialState(docId));
    dispatch(
      rectSelectionActions.updateSelections({
        docId,
        selection: selection.filter((id) => selected[id]),
      })
    );
  }
);

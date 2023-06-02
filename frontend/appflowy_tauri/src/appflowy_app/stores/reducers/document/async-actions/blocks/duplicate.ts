import { DocumentState } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { newBlock } from '$app/utils/document/block';
import { rectSelectionActions } from '$app_reducers/document/slice';
import { getDuplicateActions } from '$app/utils/document/action';

export const duplicateBelowNodeThunk = createAsyncThunk(
  'document/duplicateBelowNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as { document: DocumentState };
    const node = state.document.nodes[id];
    if (!node || !node.parent) return;
    const duplicateActions = getDuplicateActions(id, node.parent, state.document, controller);

    if (!duplicateActions) return;
    await controller.applyActions(duplicateActions.actions);

    dispatch(rectSelectionActions.updateSelections([duplicateActions.newNodeId]));
  }
);

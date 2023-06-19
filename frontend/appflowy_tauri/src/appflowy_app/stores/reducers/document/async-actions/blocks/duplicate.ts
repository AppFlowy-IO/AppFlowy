import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { rectSelectionActions } from '$app_reducers/document/slice';
import { getDuplicateActions } from '$app/utils/document/action';
import { RootState } from '$app/stores/store';

export const duplicateBelowNodeThunk = createAsyncThunk(
  'document/duplicateBelowNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const docState = state.document[docId];
    const node = docState.nodes[id];
    if (!node || !node.parent) return;
    const duplicateActions = getDuplicateActions(id, node.parent, docState, controller);

    if (!duplicateActions) return;
    await controller.applyActions(duplicateActions.actions);

    dispatch(
      rectSelectionActions.updateSelections({
        docId,
        selection: [duplicateActions.newNodeId],
      })
    );
  }
);

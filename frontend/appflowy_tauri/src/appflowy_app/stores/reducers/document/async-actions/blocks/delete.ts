import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';

import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME } from '$app/constants/document/name';

export const deleteNodeThunk = createAsyncThunk(
  'document/deleteNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const docState = state[DOCUMENT_NAME][docId];
    const node = docState.nodes[id];

    if (!node) return;
    await controller.applyActions([controller.getDeleteAction(node)]);
  }
);

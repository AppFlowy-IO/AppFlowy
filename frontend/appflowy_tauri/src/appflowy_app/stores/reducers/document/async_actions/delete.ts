import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentState } from '../slice';

export const deleteNodeThunk = createAsyncThunk(
  'document/deleteNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as { document: DocumentState };
    const node = state.document.nodes[id];
    if (!node) return;
    await controller.applyActions([controller.getDeleteAction(node)]);
  }
);

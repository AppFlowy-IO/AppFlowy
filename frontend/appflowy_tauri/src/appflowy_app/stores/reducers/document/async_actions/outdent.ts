import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';

import { DocumentState } from '$app/interfaces/document';

export const outdentNodeThunk = createAsyncThunk(
  'document/outdentNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const newPrevId = node.parent;
    if (!newPrevId) return;
    const parent = state.nodes[newPrevId];
    const newParentId = parent.parent;
    if (!newParentId) return;
    await controller.applyActions([controller.getMoveAction(node, newParentId, newPrevId)]);
  }
);

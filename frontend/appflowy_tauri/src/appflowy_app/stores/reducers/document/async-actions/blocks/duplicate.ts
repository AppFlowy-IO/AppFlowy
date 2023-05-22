import { DocumentState } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { newBlock } from '$app/utils/document/blocks/common';

export const duplicateBelowNodeThunk = createAsyncThunk(
  'document/duplicateBelowNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState } = thunkAPI;
    const state = getState() as { document: DocumentState };
    const node = state.document.nodes[id];
    if (!node) return;
    const parentId = node.parent;
    if (!parentId) return;
    // duplicate new node
    const newNode = newBlock<any>(node.type, parentId, node.data);
    await controller.applyActions([controller.getInsertAction(newNode, node.id)]);

    return newNode.id;
  }
);

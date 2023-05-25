import { BlockData, BlockType, DocumentState } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { newBlock } from '$app/utils/document/blocks/common';

export const insertAfterNodeThunk = createAsyncThunk(
  'document/insertAfterNode',
  async (payload: { id: string; controller: DocumentController; data?: BlockData<any>; type?: BlockType }, thunkAPI) => {
    const {
      controller,
      type = BlockType.TextBlock,
      data = {
        delta: [],
      },
    } = payload;
    const { getState } = thunkAPI;
    const state = getState() as { document: DocumentState };
    const node = state.document.nodes[payload.id];
    if (!node) return;
    const parentId = node.parent;
    if (!parentId) return;
    // create new node
    const newNode = newBlock<any>(type, parentId, data);
    await controller.applyActions([controller.getInsertAction(newNode, node.id)]);

    return newNode.id;
  }
);

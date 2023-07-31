import { BlockData, BlockType, DocumentState } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { newBlock } from '$app/utils/document/block';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME } from '$app/constants/document/name';

export const insertAfterNodeThunk = createAsyncThunk(
  'document/insertAfterNode',
  async (payload: { id: string; controller: DocumentController; data?: BlockData<any>; type?: BlockType }, thunkAPI) => {
    const {
      controller,
      type = BlockType.TextBlock,
      data = {
        delta: [],
      },
      id,
    } = payload;
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const docState = state[DOCUMENT_NAME][docId];
    const node = docState.nodes[id];

    if (!node) return;
    const parentId = node.parent;

    if (!parentId) return;
    // create new node
    const newNode = newBlock<any>(type, parentId, data);
    let nodeId = newNode.id;
    const actions = [controller.getInsertAction(newNode, node.id)];

    if (type === BlockType.DividerBlock) {
      const newTextNode = newBlock<any>(BlockType.TextBlock, parentId, {
        delta: [],
      });

      nodeId = newTextNode.id;
      actions.push(controller.getInsertAction(newTextNode, newNode.id));
    }

    await controller.applyActions(actions);

    return nodeId;
  }
);

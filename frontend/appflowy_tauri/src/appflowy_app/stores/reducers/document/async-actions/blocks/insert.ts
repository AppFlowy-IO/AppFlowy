import { BlockData, BlockType } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { generateId, newBlock } from '$app/utils/document/block';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME } from '$app/constants/document/name';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';
import Delta from 'quill-delta';

export const insertAfterNodeThunk = createAsyncThunk(
  'document/insertAfterNode',
  async (
    payload: {
      id: string;
      controller: DocumentController;
      type: BlockType;
      data?: BlockData<any>;
      defaultDelta?: Delta;
    },
    thunkAPI
  ) => {
    const { controller, id, type, data, defaultDelta } = payload;
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const documentState = state[DOCUMENT_NAME][docId];
    const node = documentState.nodes[id];

    if (!node) return;
    const parentId = node.parent;

    if (!parentId) return;
    // create new node
    const actions = [];
    let newNodeId;
    const deltaOperator = new BlockDeltaOperator(documentState, controller);

    if (defaultDelta) {
      newNodeId = generateId();
      actions.push(
        ...deltaOperator.getNewTextLineActions({
          blockId: newNodeId,
          parentId,
          prevId: node.id,
          delta: defaultDelta,
          type,
        })
      );
    } else {
      const newNode = newBlock<any>(type, parentId, data);

      actions.push(controller.getInsertAction(newNode, node.id));
      newNodeId = newNode.id;
    }

    if (type === BlockType.DividerBlock) {
      const nodeId = generateId();

      actions.push(
        ...deltaOperator.getNewTextLineActions({
          blockId: nodeId,
          parentId,
          prevId: newNodeId,
          delta: new Delta([{ insert: '' }]),
          type: BlockType.TextBlock,
        })
      );
      newNodeId = nodeId;
    }

    await controller.applyActions(actions);

    return newNodeId;
  }
);

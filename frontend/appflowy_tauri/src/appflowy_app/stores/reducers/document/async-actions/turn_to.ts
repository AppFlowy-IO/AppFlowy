import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockData, BlockType, DocumentState } from '$app/interfaces/document';
import { blockConfig } from '$app/constants/document/config';
import { newBlock } from '$app/utils/document/block';
import { rangeActions } from '$app_reducers/document/slice';

/**
 * transform to block
 * 1. insert block after current block
 * 2. move all children
 *    - if new block is not allowed to have children, move children to parent
 *    - otherwise, move children to new block
 * 3. delete current block
 */
export const turnToBlockThunk = createAsyncThunk(
  'document/turnToBlock',
  async (payload: { id: string; controller: DocumentController; type: BlockType; data: BlockData<any> }, thunkAPI) => {
    const { id, controller, type, data } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;

    const node = state.nodes[id];
    if (!node.parent) return;

    const parent = state.nodes[node.parent];
    const children = state.children[node.children].map((id) => state.nodes[id]);

    const block = newBlock<any>(type, parent.id, type === BlockType.DividerBlock ? {} : data);
    let caretId = block.id;
    // insert new block after current block
    let insertActions = [controller.getInsertAction(block, node.id)];
    if (type === BlockType.DividerBlock) {
      const newTextNode = newBlock<any>(BlockType.TextBlock, parent.id, data);
      insertActions.push(controller.getInsertAction(newTextNode, block.id));
      caretId = newTextNode.id;
    }
    // check if prev node is allowed to have children
    const config = blockConfig[block.type];
    // if new block is not allowed to have children, move children to parent
    const newParent = config.canAddChild ? block : parent;
    // if move children to parent, set prev to current block, otherwise the prev is empty
    const newPrev = newParent.id === parent.id ? block.id : '';
    const moveChildrenActions = controller.getMoveChildrenAction(children, newParent.id, newPrev);

    // delete current block
    const deleteAction = controller.getDeleteAction(node);

    // submit actions
    await controller.applyActions([...insertActions, ...moveChildrenActions, deleteAction]);
    // set cursor in new block
    dispatch(rangeActions.setCaret({ id: caretId, index: 0, length: 0 }));
  }
);

/**
 * transform to text block
 * 1. insert text block after current block
 * 2. move children to text block
 * 3. delete current block
 */
export const turnToTextBlockThunk = createAsyncThunk(
  'document/turnToTextBlock',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const data = {
      delta: node.data.delta,
    };

    await dispatch(
      turnToBlockThunk({
        id,
        controller,
        type: BlockType.TextBlock,
        data,
      })
    );
  }
);

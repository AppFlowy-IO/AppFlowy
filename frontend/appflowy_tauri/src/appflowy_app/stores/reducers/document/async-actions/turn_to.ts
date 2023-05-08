import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockData, BlockType, DocumentState, NestedBlock, TextDelta } from '$app/interfaces/document';
import { setCursorBeforeThunk } from '$app_reducers/document/async-actions/cursor';
import { blockConfig } from '$app/constants/document/config';
import { newBlock } from '$app/utils/document/blocks/common';
import { insertAfterNodeThunk } from '$app_reducers/document/async-actions/blocks';

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

    const block = newBlock<any>(type, parent.id, data);
    // insert new block after current block
    const insertHeadingAction = controller.getInsertAction(block, node.id);

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
    await controller.applyActions([insertHeadingAction, ...moveChildrenActions, deleteAction]);
    // set cursor in new block
    await dispatch(setCursorBeforeThunk({ id: block.id }));
  }
);

/**
 * turn to divider block
 * 1. insert text block with delta after current block
 * 2. turn current block to divider block
 */
export const turnToDividerBlockThunk = createAsyncThunk(
  'document/turnToDividerBlock',
  async (payload: { id: string; controller: DocumentController; delta: TextDelta[] }, thunkAPI) => {
    const { id, controller, delta } = payload;
    const { dispatch } = thunkAPI;
    const { payload: newNodeId } = await dispatch(
      insertAfterNodeThunk({
        id,
        controller,
        type: BlockType.TextBlock,
        data: {
          delta,
        },
      })
    );
    if (!newNodeId) return;
    await dispatch(turnToBlockThunk({ id, type: BlockType.DividerBlock, controller, data: {} }));
    dispatch(setCursorBeforeThunk({ id: newNodeId as string }));
  }
);

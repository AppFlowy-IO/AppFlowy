import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockData, BlockType } from '$app/interfaces/document';
import { blockConfig } from '$app/constants/document/config';
import { generateId, newBlock } from '$app/utils/document/block';
import { RootState } from '$app/stores/store';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';
import Delta from 'quill-delta';
import { setCursorRangeThunk } from '$app_reducers/document/async-actions/cursor';
import { blockEditActions } from '$app_reducers/document/block_edit_slice';
import { DOCUMENT_NAME, RANGE_NAME } from '$app/constants/document/name';

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
    const docId = controller.documentId;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const documentState = state[DOCUMENT_NAME][docId];
    const caret = state[RANGE_NAME][docId].caret;
    const node = documentState.nodes[id];

    if (!node.parent) return;

    const parent = documentState.nodes[node.parent];
    const children = documentState.children[node.children].map((id) => documentState.nodes[id]);
    let caretId,
      caretIndex = caret?.index || 0;
    const deltaOperator = new BlockDeltaOperator(documentState, controller);
    let delta = deltaOperator.getDeltaWithBlockId(node.id);
    // insert new block after current block
    const insertActions = [];

    if (node.type === BlockType.EquationBlock) {
      delta = new Delta([{ insert: node.data.formula }]);
    }

    if (delta && type === BlockType.EquationBlock) {
      data.formula = deltaOperator.getDeltaText(delta);
      const block = newBlock<any>(type, parent.id, data);

      insertActions.push(controller.getInsertAction(block, node.id));
      caretId = block.id;
      caretIndex = 0;
    } else if (delta && type === BlockType.DividerBlock) {
      const block = newBlock<any>(type, parent.id, data);

      insertActions.push(controller.getInsertAction(block, node.id));
      const nodeId = generateId();
      const actions = deltaOperator.getNewTextLineActions({
        blockId: nodeId,
        parentId: parent.id,
        prevId: block.id || null,
        delta: delta ? delta : new Delta([{ insert: '' }]),
        type,
        data,
      });

      caretId = nodeId;
      caretIndex = 0;
      insertActions.push(...actions);
    } else if (delta) {
      caretId = generateId();

      const actions = deltaOperator.getNewTextLineActions({
        blockId: caretId,
        parentId: parent.id,
        prevId: node.id,
        delta: delta,
        type,
        data,
      });

      insertActions.push(...actions);
    }

    if (!caretId) return;
    // check if prev node is allowed to have children
    const config = blockConfig[type];
    // if new block is not allowed to have children, move children to parent
    const newParentId = config.canAddChild ? caretId : parent.id;
    // if move children to parent, set prev to current block, otherwise the prev is empty
    const newPrev = config.canAddChild ? null : caretId;
    const moveChildrenActions = controller.getMoveChildrenAction(children, newParentId, newPrev);

    // delete current block
    const deleteAction = controller.getDeleteAction(node);

    // submit actions
    await controller.applyActions([...insertActions, ...moveChildrenActions, deleteAction]);
    dispatch(
      setCursorRangeThunk({
        docId,
        blockId: caretId,
        index: caretIndex,
        length: 0,
      })
    );
    dispatch(
      blockEditActions.setBlockEditState({
        id: docId,
        state: {
          id: caretId,
          editing: true,
        },
      })
    );
    return caretId;
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
    const { dispatch } = thunkAPI;

    await dispatch(
      turnToBlockThunk({
        id,
        controller,
        type: BlockType.TextBlock,
        data: {},
      })
    );
  }
);

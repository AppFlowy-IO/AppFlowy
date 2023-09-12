import { createAsyncThunk } from '@reduxjs/toolkit';
import { BlockData, BlockType } from '$app/interfaces/document';
import { insertAfterNodeThunk } from '$app_reducers/document/async-actions/blocks';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { rangeActions, slashCommandActions } from '$app_reducers/document/slice';
import { turnToBlockThunk } from '$app_reducers/document/async-actions/turn_to';
import { blockConfig } from '$app/constants/document/config';
import Delta, { Op } from 'quill-delta';
import { getDeltaText } from '$app/utils/document/delta';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME, RANGE_NAME } from '$app/constants/document/name';
import { blockEditActions } from '$app_reducers/document/block_edit_slice';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';

/**
 * add block below click
 * 1. if current block is not empty, insert a new block after current block
 * 2. if current block is empty, open slash command below current block
 */
export const addBlockBelowClickThunk = createAsyncThunk(
  'document/addBlockBelowClick',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const docId = controller.documentId;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as RootState).document[docId];
    const node = state.nodes[id];

    if (!node) return;
    const deltaOperator = new BlockDeltaOperator(state, controller);
    const delta = deltaOperator.getDeltaWithBlockId(id);

    // if current block is not empty, insert a new block after current block
    if (!delta || delta.length() > 1) {
      const { payload: newBlockId } = await dispatch(
        insertAfterNodeThunk({
          id: id,
          type: BlockType.TextBlock,
          controller,
          data: {},
          defaultDelta: new Delta([{ insert: '' }]),
        })
      );

      if (newBlockId) {
        dispatch(
          rangeActions.setCaret({
            docId,
            caret: { id: newBlockId as string, index: 0, length: 0 },
          })
        );
        dispatch(slashCommandActions.openSlashCommand({ docId, blockId: newBlockId as string }));
      }

      return;
    }

    // if current block is empty, open slash command
    dispatch(
      rangeActions.setCaret({
        docId,
        caret: { id, index: 0, length: 0 },
      })
    );

    dispatch(slashCommandActions.openSlashCommand({ docId, blockId: id }));
  }
);

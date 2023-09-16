import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME, MENTION_NAME, RANGE_NAME } from '$app/constants/document/name';
import Delta from 'quill-delta';
import { mentionActions } from '$app_reducers/document/mention_slice';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';
import { setCursorRangeThunk } from '$app_reducers/document/async-actions/cursor';

export enum MentionType {
  PAGE = 'page',
}
export const openMention = createAsyncThunk('document/mention/open', async (payload: { docId: string }, thunkAPI) => {
  const { docId } = payload;
  const { dispatch, getState } = thunkAPI;
  const state = getState() as RootState;
  const rangeState = state[RANGE_NAME][docId];
  const documentState = state[DOCUMENT_NAME][docId];
  const { caret } = rangeState;

  if (!caret) return;
  const { id } = caret;
  const node = documentState.nodes[id];

  if (!node.parent) {
    return;
  }

  dispatch(
    mentionActions.open({
      docId,
      blockId: id,
    })
  );
});

export const closeMention = createAsyncThunk('document/mention/close', async (payload: { docId: string }, thunkAPI) => {
  const { docId } = payload;
  const { dispatch } = thunkAPI;

  dispatch(
    mentionActions.close({
      docId,
    })
  );
});

export const formatMention = createAsyncThunk(
  'document/mention/format',
  async (
    payload: { controller: DocumentController; type: MentionType; value: string; searchTextLength: number },
    thunkAPI
  ) => {
    const { controller, type, value, searchTextLength } = payload;
    const docId = controller.documentId;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const mentionState = state[MENTION_NAME][docId];
    const { blockId } = mentionState;
    const rangeState = state[RANGE_NAME][docId];
    const documentState = state[DOCUMENT_NAME][docId];
    const caret = rangeState.caret;

    if (!caret) return;
    const index = caret.index - searchTextLength;

    const deltaOperator = new BlockDeltaOperator(documentState);

    const nodeDelta = deltaOperator.getDeltaWithBlockId(blockId);

    if (!nodeDelta) return;
    const diffDelta = new Delta()
      .retain(index)
      .delete(searchTextLength)
      .insert(`@`, {
        mention: {
          type,
          [type]: value,
        },
      });
    const applyTextDeltaAction = deltaOperator.getApplyDeltaAction(blockId, diffDelta);

    if (!applyTextDeltaAction) return;
    await controller.applyActions([applyTextDeltaAction]);
    dispatch(
      setCursorRangeThunk({
        docId,
        blockId,
        index,
        length: 0,
      })
    );
  }
);

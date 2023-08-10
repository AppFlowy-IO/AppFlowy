import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME, MENTION_NAME, RANGE_NAME } from '$app/constants/document/name';
import Delta from 'quill-delta';
import { getDeltaText } from '$app/utils/document/delta';
import { mentionActions } from '$app_reducers/document/mention_slice';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { rangeActions } from '$app_reducers/document/slice';

export enum MentionType {
  PAGE = 'page',
}
export const openMention = createAsyncThunk('document/mention/open', async (payload: { docId: string }, thunkAPI) => {
  const { docId } = payload;
  const { dispatch, getState } = thunkAPI;
  const state = getState() as RootState;
  const rangeState = state[RANGE_NAME][docId];
  const { caret } = rangeState;
  if (!caret) return;
  const { id, index } = caret;
  const node = state[DOCUMENT_NAME][docId].nodes[id];
  if (!node.parent) {
    return;
  }
  const nodeDelta = new Delta(node.data?.delta);

  const beforeDelta = nodeDelta.slice(0, index);
  const beforeText = getDeltaText(beforeDelta);
  let canOpenMention = !beforeText;
  if (!canOpenMention) {
    if (index === 1) {
      canOpenMention = beforeText.endsWith('@');
    } else {
      canOpenMention = beforeText.endsWith(' ');
    }
  }

  if (!canOpenMention) return;

  dispatch(
    mentionActions.open({
      docId,
      blockId: id,
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
    const caret = rangeState.caret;
    if (!caret) return;
    const index = caret.index - searchTextLength;

    const node = state[DOCUMENT_NAME][docId].nodes[blockId];
    const nodeDelta = new Delta(node.data?.delta);
    const diffDelta = new Delta()
      .retain(index)
      .delete(searchTextLength)
      .insert(`@`, {
        mention: {
          type,
          [type]: value,
        },
      });
    const newDelta = nodeDelta.compose(diffDelta);
    const updateAction = controller.getUpdateAction({
      ...node,
      data: {
        ...node.data,
        delta: newDelta.ops,
      },
    });

    await controller.applyActions([updateAction]);

    dispatch(rangeActions.initialState(docId));
    dispatch(rangeActions.setCaret({ docId, caret: { id: blockId, index, length: 0 } }));
  }
);

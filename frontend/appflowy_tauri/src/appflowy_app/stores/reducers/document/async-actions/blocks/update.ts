import { BlockData } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import Delta, { Op } from 'quill-delta';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME } from '$app/constants/document/name';
import { updatePageName } from '$app_reducers/pages/async_actions';
import { getDeltaText } from '$app/utils/document/delta';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';
import { openMention, closeMention } from '$app_reducers/document/async-actions/mention';

const updateNodeDeltaAfterThunk = createAsyncThunk(
  'document/updateNodeDeltaAfter',
  async (
    payload: { docId: string; id: string; ops: Op[]; newDelta: Delta; oldDelta: Delta; controller: DocumentController },
    thunkAPI
  ) => {
    const { dispatch } = thunkAPI;
    const { docId, ops, oldDelta, newDelta } = payload;
    const insertOps = ops.filter((op) => op.insert !== undefined);

    const deleteOps = ops.filter((op) => op.delete !== undefined);
    const oldText = getDeltaText(oldDelta);
    const newText = getDeltaText(newDelta);
    const deleteText = oldText.slice(newText.length);

    if (insertOps.length === 1 && insertOps[0].insert === '@') {
      dispatch(openMention({ docId }));
    }

    if (deleteOps.length === 1 && deleteText === '@') {
      dispatch(closeMention({ docId }));
    }
  }
);

export const updateNodeDeltaThunk = createAsyncThunk(
  'document/updateNodeDelta',
  async (payload: { id: string; ops: Op[]; newDelta: Delta; controller: DocumentController }, thunkAPI) => {
    const { id, ops, newDelta, controller } = payload;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const docState = state[DOCUMENT_NAME][docId];
    const node = docState.nodes[id];

    const deltaOperator = new BlockDeltaOperator(docState, controller);
    const oldDelta = deltaOperator.getDeltaWithBlockId(id);

    if (!oldDelta) return;
    const diff = oldDelta?.diff(newDelta);

    if (ops.length === 0 || diff?.ops.length === 0) return;
    // If the node is the root node, update the page name
    if (!node.parent) {
      await dispatch(
        updatePageName({
          id: docId,
          name: getDeltaText(newDelta),
        })
      );
      return;
    }

    if (!node.externalId) return;

    await controller.applyTextDelta(node.externalId, JSON.stringify(ops));
    await dispatch(updateNodeDeltaAfterThunk({ docId, id, ops, newDelta, oldDelta, controller }));
  }
);

export const updateNodeDataThunk = createAsyncThunk<
  void,
  {
    id: string;
    data: Partial<BlockData<any>>;
    controller: DocumentController;
  }
>('document/updateNodeDataExceptDelta', async (payload, thunkAPI) => {
  const { id, data, controller } = payload;
  const { getState } = thunkAPI;
  const state = getState() as RootState;
  const docId = controller.documentId;
  const docState = state[DOCUMENT_NAME][docId];
  const node = docState.nodes[id];

  const newData = { ...node.data, ...data };

  await controller.applyActions([
    controller.getUpdateAction({
      ...node,
      data: newData,
    }),
  ]);
});

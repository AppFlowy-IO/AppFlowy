import { BlockData, DocumentState } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import Delta, { Op } from 'quill-delta';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME } from '$app/constants/document/name';
import { updatePageName } from '$app_reducers/pages/async_actions';
import { getDeltaText } from '$app/utils/document/delta';

export const updateNodeDeltaThunk = createAsyncThunk(
  'document/updateNodeDelta',
  async (payload: { id: string; delta: Op[]; controller: DocumentController }, thunkAPI) => {
    const { id, delta, controller } = payload;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const docState = state[DOCUMENT_NAME][docId];
    const node = docState.nodes[id];
    const oldDelta = new Delta(node.data.delta);
    const newDelta = new Delta(delta);

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

    const diffDelta = newDelta.diff(oldDelta);

    if (diffDelta.ops.length === 0) return;

    const newData = { ...node.data, delta };

    await controller.applyActions([
      controller.getUpdateAction({
        ...node,
        data: newData,
      }),
    ]);
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

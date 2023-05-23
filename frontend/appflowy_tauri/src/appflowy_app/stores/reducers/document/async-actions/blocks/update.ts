import { DocumentState, BlockData } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import Delta, { Op } from 'quill-delta';

export const updateNodeDeltaThunk = createAsyncThunk(
  'document/updateNodeDelta',
  async (payload: { id: string; delta: Op[]; controller: DocumentController }, thunkAPI) => {
    const { id, delta, controller } = payload;
    const { getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const diffDelta = new Delta(delta).diff(new Delta(node.data.delta || []));
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
  const state = (getState() as { document: DocumentState }).document;
  const node = state.nodes[id];

  const newData = { ...node.data, ...data };

  await controller.applyActions([
    controller.getUpdateAction({
      ...node,
      data: newData,
    }),
  ]);
});

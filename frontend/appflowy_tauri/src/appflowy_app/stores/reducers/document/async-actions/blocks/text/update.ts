import { TextDelta, NestedBlock, DocumentState, BlockData } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions } from '$app_reducers/document/slice';
import { debounce } from '$app/utils/tool';
export const updateNodeDeltaThunk = createAsyncThunk(
  'document/updateNodeDelta',
  async (payload: { id: string; delta: TextDelta[]; controller: DocumentController }, thunkAPI) => {
    const { id, delta, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    // The block map should be updated immediately
    // or the component will use the old data to update the editor
    dispatch(documentActions.updateNodeData({ id, data: { delta } }));

    const node = state.nodes[id];
    // the transaction is delayed to avoid too many updates
    debounceApplyUpdate(controller, {
      ...node,
      data: {
        ...node.data,
        delta,
      },
    });
  }
);

const debounceApplyUpdate = debounce((controller: DocumentController, updateNode: NestedBlock) => {
  void controller.applyActions([
    controller.getUpdateAction({
      ...updateNode,
      data: {
        ...updateNode.data,
      },
    }),
  ]);
}, 200);

export const updateNodeDataThunk = createAsyncThunk<
  void,
  {
    id: string;
    data: Partial<BlockData<any>>;
    controller: DocumentController;
  }
>('document/updateNodeDataExceptDelta', async (payload, thunkAPI) => {
  const { id, data, controller } = payload;
  const { dispatch, getState } = thunkAPI;
  const state = (getState() as { document: DocumentState }).document;

  dispatch(documentActions.updateNodeData({ id, data: { ...data } }));

  const node = state.nodes[id];
  await controller.applyActions([
    controller.getUpdateAction({
      ...node,
      data: {
        ...node.data,
        ...data,
      },
    }),
  ]);
});

import { TextDelta } from '@/appflowy_app/interfaces/document';
import { DocumentController } from '@/appflowy_app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions, DocumentState, Node } from '../slice';
import { debounce } from '$app/utils/tool';
export const updateNodeDeltaThunk = createAsyncThunk(
  'document/updateNodeDelta',
  async (payload: { id: string; delta: TextDelta[]; controller: DocumentController }, thunkAPI) => {
    const { id, delta, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const updateNode = {
      ...node,
      id,
      data: {
        ...node.data,
        delta,
      },
    };
    // The block map should be updated immediately
    // or the component will use the old data to update the editor
    dispatch(documentActions.setBlockMap(updateNode));

    // the transaction is delayed to avoid too many updates
    debounceApplyUpdate(controller, updateNode);
  }
);

const debounceApplyUpdate = debounce((controller: DocumentController, updateNode: Node) => {
  void controller.applyActions([
    controller.getUpdateAction({
      ...updateNode,
      data: {
        ...updateNode.data,
      },
    }),
  ]);
}, 200);

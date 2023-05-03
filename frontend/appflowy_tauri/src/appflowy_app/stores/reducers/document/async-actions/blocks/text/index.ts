import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockType, DocumentState } from '$app/interfaces/document';
import { turnToBlockThunk } from '$app_reducers/document/async-actions/turn_to';

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
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const data = {
      delta: node.data.delta,
    };

    await dispatch(
      turnToBlockThunk({
        id,
        controller,
        type: BlockType.TextBlock,
        data,
      })
    );
  }
);

import { createAsyncThunk } from "@reduxjs/toolkit";
import { DocumentState, NestedBlock } from "$app/interfaces/document";

export * from './cursor';
export * from './blocks';
export * from './turn_to';

export const getBlockByIdThunk = createAsyncThunk<NestedBlock, string>(
  'document/getBlockById',
  async (id, thunkAPI) => {
    const { getState } = thunkAPI;
    const state = getState() as { document: DocumentState };
    const node = state.document.nodes[id] as NestedBlock;
    return node;
  });
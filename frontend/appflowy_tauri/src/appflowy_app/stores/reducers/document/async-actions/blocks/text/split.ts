import { BlockType, DocumentState, TextDelta } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions } from '$app_reducers/document/slice';
import { setCursorBeforeThunk } from '../../cursor';
import { newTextBlock } from '$app/utils/document/blocks/text';

export const splitNodeThunk = createAsyncThunk(
  'document/splitNode',
  async (
    payload: { id: string; retain: TextDelta[]; insert: TextDelta[]; controller: DocumentController },
    thunkAPI
  ) => {
    const { id, controller, retain, insert } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node.parent) return;
    const children = state.children[node.children];
    const prevId = children.length > 0 ? null : node.id;
    const parent = children.length > 0 ? node : state.nodes[node.parent];

    const newNode = newTextBlock(parent.id, {
      delta: insert,
    });
    const retainNode = {
      ...node,
      data: {
        ...node.data,
        delta: retain,
      },
    };
    await controller.applyActions([controller.getInsertAction(newNode, prevId), controller.getUpdateAction(retainNode)]);
    // update local node data
    dispatch(documentActions.updateNodeData({ id: retainNode.id, data: { delta: retain } }));
    // set cursor
    await dispatch(setCursorBeforeThunk({ id: newNode.id }));
  }
);

import { BlockType, TextDelta } from '@/appflowy_app/interfaces/document';
import { DocumentController } from '@/appflowy_app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { generateId } from '@/appflowy_app/utils/block';
import { documentActions, DocumentState } from '../slice';
import { setCursorBeforeThunk } from './set_cursor';

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
    const newNode = {
      id: generateId(),
      parent: parent.id,
      type: BlockType.TextBlock,
      data: {
        delta: insert,
      },
      children: generateId(),
    };
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

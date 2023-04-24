import { BlockType, TextDelta } from '@/appflowy_app/interfaces/document';
import { DocumentController } from '@/appflowy_app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { generateId } from '@/appflowy_app/utils/block';
import { documentActions, DocumentState } from '../slice';

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
    dispatch(documentActions.setBlockMap(newNode));
    dispatch(documentActions.setBlockMap(retainNode));
    dispatch(
      documentActions.setChildrenMap({
        id: newNode.children,
        childIds: [],
      })
    );
    dispatch(
      documentActions.insertChild({
        id: parent.id,
        childId: newNode.id,
        prevId,
      })
    );
  }
);

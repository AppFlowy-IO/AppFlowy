import { DocumentState, TextDelta } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions } from '$app_reducers/document/slice';
import { setCursorBeforeThunk } from '../../cursor';
import { getDefaultBlockData, newBlock } from '$app/utils/document/blocks/common';
import { blockConfig } from '$app/constants/document/config';

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
    const prevId = node.id;
    const parent = state.nodes[node.parent];

    const config = blockConfig[node.type];
    const newNodeType = config.splitType;
    const defaultData = getDefaultBlockData(newNodeType);
    const newNode = newBlock<any>(newNodeType, parent.id, {
      ...defaultData,
      delta: insert,
    });
    const retainNode = {
      ...node,
      data: {
        ...node.data,
        delta: retain,
      },
    };
    const insertAction = controller.getInsertAction(newNode, prevId);
    const updateAction = controller.getUpdateAction(retainNode);
    const moveChildrenAction = controller.getMoveChildrenAction(
      children.map((id) => state.nodes[id]),
      newNode.id,
      ''
    );
    await controller.applyActions([insertAction, ...moveChildrenAction, updateAction]);
    // update local node data
    dispatch(documentActions.updateNodeData({ id: retainNode.id, data: { delta: retain } }));
    // set cursor
    await dispatch(setCursorBeforeThunk({ id: newNode.id }));
  }
);

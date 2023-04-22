import { BlockType } from '@/appflowy_app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions, DocumentState } from '../slice';
import { outdentNodeThunk } from './outdent';

const composePrevNodeThunk = createAsyncThunk(
  'document/composePrevNode',
  async (payload: { prevNodeId: string; id: string; controller: DocumentController }, thunkAPI) => {
    const { id, prevNodeId, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const prevNode = state.nodes[prevNodeId];
    // find prev line
    let prevLineId = prevNode.id;
    while (prevLineId) {
      const prevLineChildren = state.children[state.nodes[prevLineId].children];
      if (prevLineChildren.length === 0) break;
      prevLineId = prevLineChildren[prevLineChildren.length - 1];
    }
    const prevLine = state.nodes[prevLineId];
    // merge delta
    const newPrevLine = {
      ...prevLine,
      data: {
        ...prevLine.data,
        delta: [...prevLine.data.delta, ...node.data.delta],
      },
    };
    await controller.applyActions([controller.getDeleteAction(node), controller.getUpdateAction(newPrevLine)]);

    dispatch(documentActions.setBlockMap(newPrevLine));
    dispatch(documentActions.removeBlockMapKey(node.id));
    dispatch(documentActions.removeChildrenMapKey(node.children));
  }
);

export const backspaceNodeThunk = createAsyncThunk(
  'document/backspaceNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node.parent) return;
    const parent = state.nodes[node.parent];
    const ancestorId = parent.parent;
    const children = state.children[parent.children];
    const index = children.indexOf(id);
    const prevNodeId = children[index - 1];
    const nextNodeId = children[index + 1];
    // transform to text block
    if (node.type !== BlockType.TextBlock) {
      // todo: transform to text block
    }
    // compose to previous line when it has next sibling or no ancestor
    if (nextNodeId || !ancestorId) {
      if (!prevNodeId) return;
      await dispatch(composePrevNodeThunk({ prevNodeId, id, controller }));
      return;
    } else {
      // outdent when it has no next sibling
      await dispatch(outdentNodeThunk({ id, controller }));
      return;
    }
  }
);

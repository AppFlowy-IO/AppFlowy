import { BlockType } from '@/appflowy_app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions, DocumentState } from '../slice';
import { outdentNodeThunk } from './outdent';
import { setCursorAfterThunk } from './set_cursor';

const composeNodeThunk = createAsyncThunk(
  'document/composeNode',
  async (payload: { id: string; composeId: string; controller: DocumentController }, thunkAPI) => {
    const { id, composeId, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const composeNode = state.nodes[composeId];
    // set cursor
    await dispatch(setCursorAfterThunk({ id: composeNode.id }));
    // merge delta
    const newNode = {
      ...composeNode,
      data: {
        ...composeNode.data,
        delta: [...composeNode.data.delta, ...node.data.delta],
      },
    };
    // move children
    const children = state.children[node.children];

    const moveActions = children.reverse().map((childId) => {
      return controller.getMoveAction(state.nodes[childId], newNode.id, '');
    });
    await controller.applyActions([
      ...moveActions,
      controller.getDeleteAction(node),
      controller.getUpdateAction(newNode),
    ]);

    children.reverse().forEach((childId) => {
      dispatch(documentActions.moveNode({ id: childId, newParentId: newNode.id, newPrevId: '' }));
    });
    dispatch(documentActions.setBlockMap(newNode));
    dispatch(documentActions.removeBlockMapKey(node.id));
    dispatch(documentActions.removeChildrenMapKey(node.children));
  }
);

const composeParentThunk = createAsyncThunk(
  'document/composeParent',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node.parent) return;
    await dispatch(composeNodeThunk({ id: id, composeId: node.parent, controller }));
  }
);

const composePrevNodeThunk = createAsyncThunk(
  'document/composePrevNode',
  async (payload: { prevNodeId: string; id: string; controller: DocumentController }, thunkAPI) => {
    const { id, prevNodeId, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const prevNode = state.nodes[prevNodeId];
    if (!prevNode) return;
    // find prev line
    let prevLineId = prevNode.id;
    while (prevLineId) {
      const prevLineChildren = state.children[state.nodes[prevLineId].children];
      if (prevLineChildren.length === 0) break;
      prevLineId = prevLineChildren[prevLineChildren.length - 1];
    }
    await dispatch(composeNodeThunk({ id: id, composeId: prevLineId, controller }));
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
      // do nothing when it is the first line
      if (!prevNodeId && !ancestorId) return;
      // compose to parent when it has no previous sibling
      if (!prevNodeId) {
        await dispatch(composeParentThunk({ id, controller }));
        return;
      }
      await dispatch(composePrevNodeThunk({ prevNodeId, id, controller }));
      return;
    } else {
      // outdent when it has no next sibling
      await dispatch(outdentNodeThunk({ id, controller }));
      return;
    }
  }
);

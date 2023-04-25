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
    // set cursor in compose node end
    // It must be stored before update, for the cursor can be restored after update
    await dispatch(setCursorAfterThunk({ id: composeId }));

    // merge delta and update
    const nodeDelta = node.data?.delta || [];
    const composeDelta = composeNode.data?.delta || [];
    const newNode = {
      ...composeNode,
      data: {
        ...composeNode.data,
        delta: [...composeDelta, ...nodeDelta],
      },
    };
    const updateAction = controller.getUpdateAction(newNode);

    // move children
    const children = state.children[node.children];
    // the reverse can ensure that every child will be inserted in first place and don't need to update prevId
    const moveActions = children.reverse().map((childId) => {
      return controller.getMoveAction(state.nodes[childId], newNode.id, '');
    });

    // delete node
    const deleteAction = controller.getDeleteAction(node);

    // move must be before delete
    await controller.applyActions([...moveActions, deleteAction, updateAction]);
    // update local node data
    dispatch(documentActions.updateNodeData({ id: newNode.id, data: { delta: newNode.data.delta } }));
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

import { BlockType, DocumentState } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { allowedChildrenBlockTypes } from '$app/constants/document/config';

export const indentNodeThunk = createAsyncThunk(
  'document/indentNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node.parent) return;
    // get parent
    const parent = state.nodes[node.parent];
    // get prev node
    const children = state.children[parent.children];
    const index = children.indexOf(id);
    if (index === 0) return;
    const newParentId = children[index - 1];
    const prevNode = state.nodes[newParentId];
    // check if prev node is allowed to have children
    if (!allowedChildrenBlockTypes.includes(prevNode.type)) return;
    // check if prev node has children and get last child for new prev node
    const prevNodeChildren = state.children[prevNode.children];
    const newPrevId = prevNodeChildren[prevNodeChildren.length - 1];

    await controller.applyActions([controller.getMoveAction(node, newParentId, newPrevId)]);
  }
);

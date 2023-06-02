import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentState } from '$app/interfaces/document';
import { blockConfig } from '$app/constants/document/config';

/**
 * outdent node
 * 1. if node parent is root, do nothing
 * 2. if node parent is not root, move node to after parent and record next sibling ids
 * 2.1. if next sibling ids is empty, do nothing
 * 2.2. if next sibling ids is not empty
 * 2.2.1. if node can add child, move next sibling ids to node's children
 * 2.2.2. if node can not add child, move next sibling ids to after node
 */
export const outdentNodeThunk = createAsyncThunk(
  'document/outdentNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const parentId = node.parent;
    if (!parentId) return;
    const ancestorId = state.nodes[parentId].parent;
    if (!ancestorId) return;

    const parent = state.nodes[parentId];
    const index = state.children[parent.children].indexOf(id);
    const nextSiblingIds = state.children[parent.children].slice(index + 1);

    const actions = [];
    const moveAction = controller.getMoveAction(node, ancestorId, parentId);
    actions.push(moveAction);

    const config = blockConfig[node.type];
    if (nextSiblingIds.length > 0) {
      if (config.canAddChild) {
        const children = state.children[node.children];
        let lastChildId: string | null = null;
        const lastIndex = children.length - 1;
        if (lastIndex >= 0) {
          lastChildId = children[lastIndex];
        }
        const moveChildrenActions = nextSiblingIds
          .reverse()
          .map((id) => controller.getMoveAction(state.nodes[id], node.id, lastChildId));
        actions.push(...moveChildrenActions);
      } else {
        const moveChildrenActions = nextSiblingIds
          .reverse()
          .map((id) => controller.getMoveAction(state.nodes[id], ancestorId, node.id));
        actions.push(...moveChildrenActions);
      }
    }

    await controller.applyActions(actions);
  }
);

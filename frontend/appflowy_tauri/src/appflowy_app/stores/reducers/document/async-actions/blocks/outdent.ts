import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { blockConfig } from '$app/constants/document/config';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME } from '$app/constants/document/name';

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
    const state = getState() as RootState;
    const docId = controller.documentId;
    const docState = state[DOCUMENT_NAME][docId];
    const node = docState.nodes[id];
    const parentId = node.parent;

    if (!parentId) return;
    const ancestorId = docState.nodes[parentId].parent;

    if (!ancestorId) return;

    const parent = docState.nodes[parentId];
    const index = docState.children[parent.children].indexOf(id);
    const nextSiblingIds = docState.children[parent.children].slice(index + 1);

    const actions = [];
    const moveAction = controller.getMoveAction(node, ancestorId, parentId);

    actions.push(moveAction);

    const config = blockConfig[node.type];

    if (nextSiblingIds.length > 0) {
      if (config.canAddChild) {
        const children = docState.children[node.children];
        let lastChildId: string | null = null;
        const lastIndex = children.length - 1;

        if (lastIndex >= 0) {
          lastChildId = children[lastIndex];
        }

        const moveChildrenActions = nextSiblingIds
          .reverse()
          .map((id) => controller.getMoveAction(docState.nodes[id], node.id, lastChildId));

        actions.push(...moveChildrenActions);
      } else {
        const moveChildrenActions = nextSiblingIds
          .reverse()
          .map((id) => controller.getMoveAction(docState.nodes[id], ancestorId, node.id));

        actions.push(...moveChildrenActions);
      }
    }

    await controller.applyActions(actions);
  }
);

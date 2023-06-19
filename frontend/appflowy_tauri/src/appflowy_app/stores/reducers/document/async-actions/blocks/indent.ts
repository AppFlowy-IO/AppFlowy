import { DocumentState } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { blockConfig } from '$app/constants/document/config';
import { getPrevNodeId } from '$app/utils/document/block';
import { RootState } from '$app/stores/store';

/**
 * indent node
 * 1. if node parent is root, do nothing
 * 2. if node parent is not root
 * 2.1. get prev node, if prev node is not allowed to have children, do nothing
 * 2.2. if prev node is allowed to have children, move node to prev node's last child, and move node's children after node
 */
export const indentNodeThunk = createAsyncThunk(
  'document/indentNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const docState = state.document[docId];
    const node = docState.nodes[id];
    if (!node.parent) return;

    // get prev node
    const prevNodeId = getPrevNodeId(docState, id);
    if (!prevNodeId) return;
    const newParentNode = docState.nodes[prevNodeId];
    // check if prev node is allowed to have children
    const config = blockConfig[newParentNode.type];
    if (!config.canAddChild) return;

    // check if prev node has children and get last child for new prev node
    const newParentChildren = docState.children[newParentNode.children];
    const newPrevId = newParentChildren[newParentChildren.length - 1];

    const moveAction = controller.getMoveAction(node, newParentNode.id, newPrevId);
    const childrenNodes = docState.children[node.children].map((id) => docState.nodes[id]);
    const moveChildrenActions = controller.getMoveChildrenAction(childrenNodes, newParentNode.id, node.id);

    await controller.applyActions([moveAction, ...moveChildrenActions]);
  }
);

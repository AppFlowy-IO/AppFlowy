import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions, DocumentState } from '../slice';

export const deleteNodeThunk = createAsyncThunk(
  'document/deleteNode',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as { document: DocumentState };
    const node = state.document.nodes[id];
    if (!node) return;
    await controller.applyActions([controller.getDeleteAction(node)]);

    const deleteNode = (deleteId: string) => {
      const deleteItem = state.document.nodes[deleteId];
      const children = state.document.children[deleteItem.children];
      // delete children
      if (children.length > 0) {
        children.forEach((childId) => {
          deleteNode(childId);
        });
      }
      dispatch(documentActions.removeBlockMapKey(deleteItem.id));
      dispatch(documentActions.removeChildrenMapKey(deleteItem.children));
    };
    deleteNode(node.id);

    if (!node.parent) return;
    dispatch(documentActions.deleteChild({ id: node.parent, childId: node.id }));
  }
);

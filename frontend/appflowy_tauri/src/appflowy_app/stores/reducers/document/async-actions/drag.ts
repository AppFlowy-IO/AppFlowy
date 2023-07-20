import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { DragInsertType } from '$app_reducers/block-draggable/slice';
import { DocumentController } from '$app/stores/effects/document/document_controller';

export const dragThunk = createAsyncThunk(
  'document/drag',
  async (
    payload: {
      draggingId: string;
      dropId: string;
      insertType: DragInsertType;
      controller: DocumentController;
    },
    thunkAPI
  ) => {
    const { getState } = thunkAPI;
    const { draggingId, dropId, insertType, controller } = payload;
    const docId = controller.documentId;
    const documentState = (getState() as RootState).document[docId];
    const { nodes, children } = documentState;
    const draggingNode = nodes[draggingId];
    const targetNode = nodes[dropId];
    const targetChildren = children[targetNode.children] || [];
    const targetParentId = targetNode.parent;

    if (!targetParentId) return;
    const targetParent = nodes[targetParentId];
    const targetParentChildren = children[targetParent.children] || [];
    let prevId, parentId;

    if (insertType === DragInsertType.BEFORE) {
      const targetIndex = targetParentChildren.indexOf(dropId);
      const prevIndex = targetIndex - 1;

      parentId = targetParentId;
      if (prevIndex >= 0) {
        prevId = targetParentChildren[prevIndex];
      }
    } else if (insertType === DragInsertType.AFTER) {
      prevId = dropId;
      parentId = targetParentId;
    } else {
      parentId = dropId;
      if (targetChildren.length > 0) {
        prevId = targetChildren[targetChildren.length - 1];
      }
    }

    const actions = [controller.getMoveAction(draggingNode, parentId, prevId || null)];

    await controller.applyActions(actions);
  }
);

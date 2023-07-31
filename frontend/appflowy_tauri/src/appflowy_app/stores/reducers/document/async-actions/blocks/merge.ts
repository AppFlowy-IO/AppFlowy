import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { DocumentState } from '$app/interfaces/document';
import Delta from 'quill-delta';
import { blockConfig } from '$app/constants/document/config';
import { getMoveChildrenActions } from '$app/utils/document/action';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME } from '$app/constants/document/name';

/**
 * Merge two blocks
 * 1. merge delta
 * 2. move children
 * 3. delete current block
 */
export const mergeDeltaThunk = createAsyncThunk(
  'document/mergeDelta',
  async (payload: { sourceId: string; targetId: string; controller: DocumentController }, thunkAPI) => {
    const { sourceId, targetId, controller } = payload;
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const docState = state[DOCUMENT_NAME][docId];
    const target = docState.nodes[targetId];
    const source = docState.nodes[sourceId];

    if (!target || !source) return;
    const targetDelta = new Delta(target.data.delta);
    const sourceDelta = new Delta(source.data.delta);
    const mergeDelta = targetDelta.concat(sourceDelta);
    const ops = mergeDelta.ops;
    const updateAction = controller.getUpdateAction({
      ...target,
      data: {
        ...target.data,
        delta: ops,
      },
    });

    const actions = [updateAction];
    // move children
    const children = docState.children[source.children].map((id) => docState.nodes[id]);
    const moveActions = getMoveChildrenActions({
      controller,
      children,
      target,
    });

    actions.push(...moveActions);
    // delete current block
    const deleteAction = controller.getDeleteAction(source);

    actions.push(deleteAction);

    await controller.applyActions(actions);
  }
);

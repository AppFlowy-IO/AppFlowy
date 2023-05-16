import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { DocumentState } from '$app/interfaces/document';
import { getCollapsedRange, getPrevLineId } from "$app/utils/document/blocks/common";
import { rangeSelectionActions } from "$app_reducers/document/slice";
import { blockConfig } from '$app/constants/document/config';
import { getNodeEndSelection } from '$app/utils/document/blocks/text/delta';

/**
 * It will merge delta to the prev line
 * 1. find the prev line and has delta
 *    1.1 Set cursor after the prev line
 *    1.2 merge delta
 * 2. If deleteCurrentNode is true, delete the current node and move children
 *    2.2.1 if the prev line can add children, move children to the prev line.
 *    2.2.2 Otherwise, move children to the parent and below the prev line
 * 3. If deleteCurrentNode is false, clear the current node delta
 */
export const mergeToPrevLineThunk = createAsyncThunk(
  'document/codeBlockBackspace',
  async (payload: { id: string; controller: DocumentController; deleteCurrentNode?: boolean }, thunkAPI) => {
    const { id, controller, deleteCurrentNode = false } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const prevLineId = getPrevLineId(state, id);
    if (!prevLineId) return;
    let prevLine = state.nodes[prevLineId];
    // Find the prev line that has delta
    while (prevLine && !prevLine.data.delta) {
      const id = getPrevLineId(state, prevLine.id);
      if (!id) return;
      prevLine = state.nodes[id];
    }
    if (!prevLine) return;

    const prevLineDelta = prevLine.data.delta;

    const selection = getNodeEndSelection(prevLineDelta);

    const mergeDelta = [...prevLineDelta, ...node.data.delta];

    const updateAction = controller.getUpdateAction({
      ...prevLine,
      data: {
        ...prevLine.data,
        delta: mergeDelta,
      },
    });

    const actions = [updateAction];

    if (deleteCurrentNode) {
      // move children
      const config = blockConfig[prevLine.type];
      const children = state.children[node.children].map((id) => state.nodes[id]);
      const targetParentId = config.canAddChild ? prevLine.id : prevLine.parent;
      if (!targetParentId) return;
      const targetPrevId = targetParentId === prevLine.id ? '' : prevLine.id;
      const moveActions = controller.getMoveChildrenAction(children, targetParentId, targetPrevId);
      actions.push(...moveActions);
      // delete current block
      const deleteAction = controller.getDeleteAction(node);
      actions.push(deleteAction);
    } else {
      // clear current block delta
      const updateAction = controller.getUpdateAction({
        ...node,
        data: {
          ...node.data,
          delta: [],
        },
      });
      actions.push(updateAction);
    }
    await controller.applyActions(actions);

    // set cursor after the prev line
    const range = getCollapsedRange(prevLine.id, selection);
    dispatch(rangeSelectionActions.setRange(range));
  }
);

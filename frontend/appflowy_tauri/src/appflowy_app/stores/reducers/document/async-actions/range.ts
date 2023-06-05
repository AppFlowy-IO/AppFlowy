import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { rangeActions } from '$app_reducers/document/slice';
import Delta from 'quill-delta';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import {
  getAfterMergeCaretByRange,
  getInsertEnterNodeAction,
  getMergeEndDeltaToStartActionsByRange,
  getMiddleIds,
  getMiddleIdsByRange,
  getStartAndEndExtentDelta,
} from '$app/utils/document/action';
import { RangeState, SplitRelationship } from '$app/interfaces/document';
import { blockConfig } from '$app/constants/document/config';

interface storeRangeThunkPayload {
  id: string;
  range: {
    index: number;
    length: number;
  };
}

/**
 * store range to redux store
 * 1. if isDragging is false, just store range
 * 2. if isDragging is true, we need amend range between anchor and focus
 */
export const storeRangeThunk = createAsyncThunk('document/storeRange', (payload: storeRangeThunkPayload, thunkAPI) => {
  const { id, range } = payload;
  const { dispatch, getState } = thunkAPI;
  const state = getState() as RootState;
  const rangeState = state.documentRange;
  // we need amend range between anchor and focus
  const { anchor, focus, isDragging } = rangeState;
  if (!isDragging || !anchor || !focus) return;

  const ranges: RangeState['ranges'] = {};
  ranges[id] = range;
  // pin anchor index
  let anchorIndex = anchor.point.index;
  let anchorLength = anchor.point.length;
  if (anchorIndex === undefined || anchorLength === undefined) {
    dispatch(rangeActions.setAnchorPointRange(range));
    anchorIndex = range.index;
    anchorLength = range.length;
  }

  // if anchor and focus are in the same node, we don't need to amend range
  if (anchor.id === id) {
    dispatch(rangeActions.setRanges(ranges));
    return;
  }

  // amend anchor range because slatejs will stop update selection when dragging quickly
  const isForward = anchor.point.y < focus.point.y;
  const anchorDelta = new Delta(state.document.nodes[anchor.id].data.delta);
  if (isForward) {
    const selectedDelta = anchorDelta.slice(anchorIndex);
    ranges[anchor.id] = {
      index: anchorIndex,
      length: selectedDelta.length(),
    };
  } else {
    const selectedDelta = anchorDelta.slice(0, anchorIndex + anchorLength);
    ranges[anchor.id] = {
      index: 0,
      length: selectedDelta.length(),
    };
  }

  // select all ids between anchor and focus
  const startId = isForward ? anchor.id : focus.id;
  const endId = isForward ? focus.id : anchor.id;

  const middleIds = getMiddleIds(state.document, startId, endId);
  middleIds.forEach((id) => {
    const node = state.document.nodes[id];

    if (!node || !node.data.delta) return;
    const delta = new Delta(node.data.delta);
    const rangeStatic = {
      index: 0,
      length: delta.length(),
    };

    ranges[id] = rangeStatic;
  });

  dispatch(rangeActions.setRanges(ranges));
});

/**
 * delete range and insert delta
 * 1. merge start and end delta to start node and delete end node
 * 2. delete middle nodes
 * 3. clear range
 */
export const deleteRangeAndInsertThunk = createAsyncThunk(
  'document/deleteRange',
  async (payload: { controller: DocumentController; insertDelta?: Delta }, thunkAPI) => {
    const { controller, insertDelta } = payload;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const rangeState = state.documentRange;
    // if no range, just return
    if (rangeState.caret && rangeState.caret.length === 0) return;
    const actions = [];
    // get merge actions
    const mergeActions = getMergeEndDeltaToStartActionsByRange(state, controller, insertDelta);
    if (mergeActions) {
      actions.push(...mergeActions);
    }
    // get middle nodes
    const middleIds = getMiddleIdsByRange(rangeState, state.document);
    // delete middle nodes
    const deleteMiddleNodesActions = middleIds?.map((id) => controller.getDeleteAction(state.document.nodes[id])) || [];
    actions.push(...deleteMiddleNodesActions);

    const caret = getAfterMergeCaretByRange(rangeState, insertDelta);

    // apply actions
    await controller.applyActions(actions);

    // clear range
    dispatch(rangeActions.clearRange());
    if (caret) {
      dispatch(rangeActions.setCaret(caret));
    }
  }
);

/**
 * delete range and insert enter
 * 1. if shift key, insert '\n' to start node and concat end node delta
 * 2. if not shift key
 *    2.1 insert node under start node, and concat end node delta to insert node
 *    2.2 filter rest children and move to insert node, if need
 * 3. delete middle nodes
 * 4. clear range
 */
export const deleteRangeAndInsertEnterThunk = createAsyncThunk(
  'document/deleteRangeAndInsertEnter',
  async (payload: { controller: DocumentController; shiftKey: boolean }, thunkAPI) => {
    const { controller, shiftKey } = payload;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const rangeState = state.documentRange;
    const actions = [];

    const { startDelta, endDelta, endNode, startNode } = getStartAndEndExtentDelta(state) || {};
    if (!startDelta || !endDelta || !endNode || !startNode) return;

    // get middle nodes
    const middleIds = getMiddleIds(state.document, startNode.id, endNode.id);

    let newStartDelta = new Delta(startDelta);
    let caret = null;
    if (shiftKey) {
      newStartDelta = newStartDelta.insert('\n').concat(endDelta);
      caret = getAfterMergeCaretByRange(rangeState, new Delta().insert('\n'));
    } else {
      const insertNodeDelta = new Delta(endDelta);
      const insertNodeAction = getInsertEnterNodeAction(startNode, insertNodeDelta, controller);
      if (!insertNodeAction) return;
      actions.push(insertNodeAction.action);
      caret = {
        id: insertNodeAction.id,
        index: 0,
        length: 0,
      };
      // move start node children to insert node
      const needMoveChildren =
        blockConfig[startNode.type].splitProps?.nextLineRelationShip === SplitRelationship.NextSibling;
      if (needMoveChildren) {
        // filter children by delete middle ids
        const children = state.document.children[startNode.children].filter((id) => middleIds?.includes(id));
        const moveChildrenAction = needMoveChildren
          ? controller.getMoveChildrenAction(
              children.map((id) => state.document.nodes[id]),
              insertNodeAction.id,
              ''
            )
          : [];
        actions.push(...moveChildrenAction);
      }
    }

    // udpate start node
    const updateAction = controller.getUpdateAction({
      ...startNode,
      data: {
        ...startNode.data,
        delta: newStartDelta.ops,
      },
    });
    if (endNode.id !== startNode.id) {
      // delete end node
      const deleteAction = controller.getDeleteAction(endNode);
      actions.push(updateAction, deleteAction);
    }

    // delete middle nodes
    const deleteMiddleNodesActions = middleIds?.map((id) => controller.getDeleteAction(state.document.nodes[id])) || [];
    actions.push(...deleteMiddleNodesActions);

    // apply actions
    await controller.applyActions(actions);

    // clear range
    dispatch(rangeActions.clearRange());
    if (caret) {
      dispatch(rangeActions.setCaret(caret));
    }
  }
);

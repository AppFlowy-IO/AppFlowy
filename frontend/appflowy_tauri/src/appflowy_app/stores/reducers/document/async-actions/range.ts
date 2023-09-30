import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { rangeActions } from '$app_reducers/document/slice';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { getMiddleIds, getStartAndEndIdsByRange } from '$app/utils/document/action';
import { RangeState } from '$app/interfaces/document';
import { DOCUMENT_NAME, RANGE_NAME } from '$app/constants/document/name';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';
import { setCursorRangeThunk } from '$app_reducers/document/async-actions/cursor';
import { updatePageName } from '$app_reducers/pages/async_actions';

interface storeRangeThunkPayload {
  docId: string;
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
  const { docId, id, range } = payload;
  const { dispatch, getState } = thunkAPI;
  const state = getState() as RootState;
  const rangeState = state[RANGE_NAME][docId];
  const documentState = state[DOCUMENT_NAME][docId];
  // we need amend range between anchor and focus
  const { anchor, focus, isDragging } = rangeState;

  if (!isDragging || !anchor || !focus) return;

  const ranges: RangeState['ranges'] = {};

  ranges[id] = range;
  // pin anchor index
  let anchorIndex = anchor.point.index;
  let anchorLength = anchor.point.length;

  if (anchorIndex === undefined || anchorLength === undefined) {
    dispatch(
      rangeActions.setAnchorPointRange({
        ...range,
        docId,
      })
    );
    anchorIndex = range.index;
    anchorLength = range.length;
  }

  // if anchor and focus are in the same node, we don't need to amend range
  if (anchor.id === id) {
    dispatch(
      rangeActions.setRanges({
        ranges,
        docId,
      })
    );
    return;
  }

  // amend anchor range because slatejs will stop update selection when dragging quickly
  const isForward = anchor.point.y < focus.point.y;
  const deltaOperator = new BlockDeltaOperator(documentState);

  if (isForward) {
    const selectedDelta = deltaOperator.sliceDeltaWithBlockId(anchor.id, anchorIndex);

    if (!selectedDelta) return;
    ranges[anchor.id] = {
      index: anchorIndex,
      length: selectedDelta.length(),
    };
  } else {
    const selectedDelta = deltaOperator.sliceDeltaWithBlockId(anchor.id, 0, anchorIndex + anchorLength);

    if (!selectedDelta) return;
    ranges[anchor.id] = {
      index: 0,
      length: selectedDelta.length(),
    };
  }

  // select all ids between anchor and focus
  const startId = isForward ? anchor.id : focus.id;
  const endId = isForward ? focus.id : anchor.id;

  const middleIds = getMiddleIds(documentState, startId, endId);

  middleIds.forEach((id) => {
    const node = documentState.nodes[id];

    if (!node) return;
    const delta = deltaOperator.getDeltaWithBlockId(node.id);

    if (!delta) return;
    const rangeStatic = {
      index: 0,
      length: delta.length(),
    };

    ranges[id] = rangeStatic;
  });

  dispatch(
    rangeActions.setRanges({
      ranges,
      docId,
    })
  );
});

/**
 * delete range and insert delta
 * 1. merge start and end delta to start node and delete end node
 * 2. delete middle nodes
 * 3. move end node's children to start node
 * 3. clear range
 */
export const deleteRangeAndInsertThunk = createAsyncThunk(
  'document/deleteRange',
  async (payload: { controller: DocumentController; insertChar?: string }, thunkAPI) => {
    const { controller, insertChar } = payload;
    const docId = controller.documentId;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const rangeState = state[RANGE_NAME][docId];
    const documentState = state[DOCUMENT_NAME][docId];
    const deltaOperator = new BlockDeltaOperator(documentState, controller, async (name: string) => {
      await dispatch(
        updatePageName({
          id: docId,
          name,
        })
      );
    });
    const [startId, endId] = getStartAndEndIdsByRange(rangeState);
    const startSelection = rangeState.ranges[startId];
    const endSelection = rangeState.ranges[endId];

    if (!startSelection || !endSelection) return;
    const id = await deltaOperator.deleteText(
      {
        id: startId,
        index: startSelection.index,
      },
      {
        id: endId,
        index: endSelection.length,
      },
      insertChar
    );

    if (!id) return;
    dispatch(
      setCursorRangeThunk({
        docId,
        blockId: id,
        index: insertChar ? startSelection.index + insertChar.length : startSelection.index,
        length: 0,
      })
    );
  }
);

/**
 * delete range and insert enter
 * 1. if shift key, insert '\n' to start node and concat end node delta
 * 2. if not shift key
 *    2.1 insert node under start node
 *    2.2 filter rest children and move to insert node, if need
 * 3. delete middle nodes
 * 4. clear range
 */
export const deleteRangeAndInsertEnterThunk = createAsyncThunk(
  'document/deleteRangeAndInsertEnter',
  async (payload: { controller: DocumentController; shiftKey: boolean }, thunkAPI) => {
    const { controller, shiftKey } = payload;
    const { getState, dispatch } = thunkAPI;
    const docId = controller.documentId;
    const state = getState() as RootState;
    const rangeState = state[RANGE_NAME][docId];
    const documentState = state[DOCUMENT_NAME][docId];
    const deltaOperator = new BlockDeltaOperator(documentState, controller, async (name: string) => {
      await dispatch(
        updatePageName({
          id: docId,
          name,
        })
      );
    });
    const [startId, endId] = getStartAndEndIdsByRange(rangeState);
    const startSelection = rangeState.ranges[startId];
    const endSelection = rangeState.ranges[endId];

    if (!startSelection || !endSelection) return;
    const newLineId = await deltaOperator.splitText(
      {
        id: startId,
        index: startSelection.index,
      },
      {
        id: endId,
        index: endSelection.length,
      },
      shiftKey
    );

    if (!newLineId) return;
    dispatch(
      setCursorRangeThunk({
        docId,
        blockId: newLineId,
        index: shiftKey ? startSelection.index + 1 : 0,
        length: 0,
      })
    );
  }
);

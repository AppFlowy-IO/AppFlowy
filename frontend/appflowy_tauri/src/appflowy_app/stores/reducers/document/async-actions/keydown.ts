import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockType, RangeStatic } from '$app/interfaces/document';
import { turnToTextBlockThunk } from '$app_reducers/document/async-actions/turn_to';
import {
  getLeftCaretByRange,
  getRightCaretByRange,
  transformToNextLineCaret,
  transformToPrevLineCaret,
} from '$app/utils/document/action';
import { indentNodeThunk, outdentNodeThunk } from '$app_reducers/document/async-actions/blocks';
import { rangeActions } from '$app_reducers/document/slice';
import { RootState } from '$app/stores/store';
import { Keyboard } from '$app/constants/document/keyboard';
import { DOCUMENT_NAME, RANGE_NAME } from '$app/constants/document/name';
import { getPreviousWordIndex } from '$app/utils/document/delta';
import { updatePageName } from '$app_reducers/pages/async_actions';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';
import { setCursorRangeThunk } from '$app_reducers/document/async-actions/cursor';

/**
 - Deletes a block using the backspace or delete key.
 - If the block is not a text block, it is converted into a text block.
 - If the block is a text block:
 - - If the block has a next sibling, it is merged into the prev line (including its children).
 - - If the block has no next sibling, it is outdented (moved to a higher level in the hierarchy).
 */
export const backspaceDeleteActionForBlockThunk = createAsyncThunk(
  'document/backspaceDeleteActionForBlock',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const docId = controller.documentId;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as RootState).document[docId];
    const node = state.nodes[id];

    if (!node.parent) return;
    const deltaOperator = new BlockDeltaOperator(state, controller, async (name: string) => {
      await dispatch(
        updatePageName({
          id: docId,
          name,
        })
      );
    });
    const parent = state.nodes[node.parent];
    const children = state.children[parent.children];
    const index = children.indexOf(id);
    const nextNodeId = children[index + 1];

    // turn to text block
    if (node.type !== BlockType.TextBlock) {
      await dispatch(turnToTextBlockThunk({ id, controller }));
      return;
    }

    const isTopLevel = parent.type === BlockType.PageBlock;

    if (isTopLevel || nextNodeId) {
      // merge to previous line
      const prevLineId = deltaOperator.findPrevTextLine(id);

      if (!prevLineId) return;

      const res = await deltaOperator.mergeText(prevLineId, id);

      console.log('res', res);
      if (!res) return;
      const caret = {
        id: res.id,
        index: res.index,
        length: 0,
      };

      dispatch(
        setCursorRangeThunk({
          docId,
          blockId: caret.id,
          index: caret.index,
          length: caret.length,
        })
      );

      return;
    }

    // outdent
    await dispatch(outdentNodeThunk({ id, controller }));
  }
);

/**
 * enter key handler
 * 1. If node is empty, and it is not a text block, turn it into a text block.
 * 2. Otherwise, split the node into two nodes.
 */
export const enterActionForBlockThunk = createAsyncThunk(
  'document/insertNodeByEnter',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const docId = controller.documentId;
    const documentState = state[DOCUMENT_NAME][docId];
    const node = documentState.nodes[id];
    const caret = state[RANGE_NAME][docId]?.caret;

    if (!node || !caret || caret.id !== id) return;

    const deltaOperator = new BlockDeltaOperator(documentState, controller, async (name: string) => {
      await dispatch(
        updatePageName({
          id: docId,
          name,
        })
      );
    });
    const isDocumentTitle = !node.parent;
    let newLineId;

    const delta = deltaOperator.getDeltaWithBlockId(node.id);

    if (!delta) return;
    if (!isDocumentTitle && delta.length() === 0 && node.type !== BlockType.TextBlock) {
      // If the node is not a text block, turn it to a text block
      await dispatch(turnToTextBlockThunk({ id, controller }));
      return;
    }

    newLineId = await deltaOperator.splitText(
      {
        id: node.id,
        index: caret.index,
      },
      {
        id: node.id,
        index: caret.index + caret.length,
      }
    );

    if (!newLineId) return;
    dispatch(
      setCursorRangeThunk({
        docId,
        blockId: newLineId,
        index: 0,
        length: 0,
      })
    );
  }
);

export const tabActionForBlockThunk = createAsyncThunk(
  'document/tabActionForBlock',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { dispatch } = thunkAPI;

    return dispatch(indentNodeThunk(payload));
  }
);

export const upDownActionForBlockThunk = createAsyncThunk(
  'document/upActionForBlock',
  async (payload: { docId: string; id: string; down?: boolean }, thunkAPI) => {
    const { docId, id, down } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const documentState = state[DOCUMENT_NAME][docId];
    const rangeState = state[RANGE_NAME][docId];
    const caret = rangeState.caret;
    const node = documentState.nodes[id];

    if (!node || !caret || id !== caret.id) return;

    let newCaret;

    if (down) {
      newCaret = transformToNextLineCaret(documentState, caret);
    } else {
      newCaret = transformToPrevLineCaret(documentState, caret);
    }

    if (!newCaret) {
      return;
    }

    dispatch(rangeActions.initialState(docId));
    dispatch(
      rangeActions.setCaret({
        docId,
        caret: newCaret,
      })
    );
  }
);

export const leftActionForBlockThunk = createAsyncThunk(
  'document/leftActionForBlock',
  async (payload: { docId: string; id: string }, thunkAPI) => {
    const { id, docId } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const documentState = state[DOCUMENT_NAME][docId];
    const rangeState = state[RANGE_NAME][docId];
    const caret = rangeState.caret;
    const node = documentState.nodes[id];

    if (!node || !caret || id !== caret.id) return;
    let newCaret: RangeStatic;
    const deltaOperator = new BlockDeltaOperator(documentState);
    const delta = deltaOperator.getDeltaWithBlockId(node.id);

    if (!delta) return;
    if (caret.length > 0) {
      newCaret = {
        id,
        index: caret.index,
        length: 0,
      };
    } else {
      if (caret.index > 0) {
        const newIndex = getPreviousWordIndex(delta, caret.index);

        newCaret = {
          id,
          index: newIndex,
          length: 0,
        };
      } else {
        const prevNodeId = deltaOperator.findPrevTextLine(id);

        if (!prevNodeId) return;
        const prevDelta = deltaOperator.getDeltaWithBlockId(prevNodeId);

        if (!prevDelta) return;
        newCaret = {
          id: prevNodeId,
          index: prevDelta.length(),
          length: 0,
        };
      }
    }

    if (!newCaret) {
      return;
    }

    dispatch(rangeActions.initialState(docId));
    dispatch(
      rangeActions.setCaret({
        docId,
        caret: newCaret,
      })
    );
  }
);

export const rightActionForBlockThunk = createAsyncThunk(
  'document/rightActionForBlock',
  async (payload: { id: string; docId: string }, thunkAPI) => {
    const { id, docId } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const documentState = state[DOCUMENT_NAME][docId];
    const rangeState = state[RANGE_NAME][docId];
    const caret = rangeState.caret;
    const node = documentState.nodes[id];

    if (!node || !caret || id !== caret.id) return;
    let newCaret: RangeStatic;
    const deltaOperator = new BlockDeltaOperator(documentState);
    const delta = deltaOperator.getDeltaWithBlockId(node.id);

    if (!delta) return;
    const deltaLength = delta.length();

    if (caret.length > 0) {
      newCaret = {
        id,
        index: caret.index + caret.length,
        length: 0,
      };
    } else {
      if (caret.index < deltaLength) {
        const newIndex = caret.index + caret.length + 1;

        newCaret = {
          id,
          index: newIndex > deltaLength ? deltaLength : newIndex,
          length: 0,
        };
      } else {
        const nextNodeId = deltaOperator.findNextTextLine(id);

        if (!nextNodeId) return;
        newCaret = {
          id: nextNodeId,
          index: 0,
          length: 0,
        };
      }
    }

    if (!newCaret) {
      return;
    }

    dispatch(rangeActions.initialState(docId));

    dispatch(
      rangeActions.setCaret({
        caret: newCaret,
        docId,
      })
    );
  }
);

export const shiftTabActionForBlockThunk = createAsyncThunk(
  'document/shiftTabActionForBlock',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { dispatch } = thunkAPI;

    return dispatch(outdentNodeThunk(payload));
  }
);

export const arrowActionForRangeThunk = createAsyncThunk(
  'document/arrowLeftActionForRange',
  async (
    payload: {
      key: string;
      docId: string;
    },
    thunkAPI
  ) => {
    const { dispatch, getState } = thunkAPI;
    const { key, docId } = payload;
    const state = getState() as RootState;
    const documentState = state[DOCUMENT_NAME][docId];
    const rangeState = state[RANGE_NAME][docId];
    let caret;
    const leftCaret = getLeftCaretByRange(rangeState);
    const rightCaret = getRightCaretByRange(rangeState);

    if (!leftCaret || !rightCaret) return;

    switch (key) {
      case Keyboard.keys.LEFT:
        caret = leftCaret;
        break;
      case Keyboard.keys.RIGHT:
        caret = rightCaret;
        break;
      case Keyboard.keys.UP:
        caret = transformToPrevLineCaret(documentState, leftCaret);
        break;
      case Keyboard.keys.DOWN:
        caret = transformToNextLineCaret(documentState, rightCaret);
        break;
    }

    if (!caret) return;
    dispatch(rangeActions.initialState(docId));
    dispatch(
      rangeActions.setCaret({
        docId,
        caret,
      })
    );
  }
);

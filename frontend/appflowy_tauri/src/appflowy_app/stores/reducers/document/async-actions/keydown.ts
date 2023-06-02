import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockType, DocumentState, SplitRelationship } from '$app/interfaces/document';
import { turnToTextBlockThunk } from '$app_reducers/document/async-actions/turn_to';
import {
  findNextHasDeltaNode,
  findPrevHasDeltaNode,
  getInsertEnterNodeAction,
  getLeftCaretByRange,
  getRightCaretByRange,
  transformToNextLineCaret,
  transformToPrevLineCaret,
} from '$app/utils/document/action';
import Delta from 'quill-delta';
import { indentNodeThunk, mergeDeltaThunk, outdentNodeThunk } from '$app_reducers/document/async-actions/blocks';
import { rangeActions } from '$app_reducers/document/slice';
import { RootState } from '$app/stores/store';
import { blockConfig } from '$app/constants/document/config';
import { Keyboard } from '$app/constants/document/keyboard';

/**
 * Delete a block by backspace or delete key
 * 1. If the block is not a text block, turn it to a text block
 * 2. If the block is a text block
 *   2.1 If the block has next node or is top level, merge it to the previous line
 *   2.2 If the block has no next node and is not top level, outdent it
 */
export const backspaceDeleteActionForBlockThunk = createAsyncThunk(
  'document/backspaceDeleteActionForBlock',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node.parent) return;
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
      const prevLine = findPrevHasDeltaNode(state, id);
      if (!prevLine) return;
      const caretIndex = new Delta(prevLine.data.delta).length();
      const caret = {
        id: prevLine.id,
        index: caretIndex,
        length: 0,
      };
      await dispatch(
        mergeDeltaThunk({
          sourceId: id,
          targetId: prevLine.id,
          controller,
        })
      );
      dispatch(rangeActions.setCaret(caret));
      return;
    }
    // outdent
    await dispatch(outdentNodeThunk({ id, controller }));
  }
);

/**
 * Insert a new node after the current node by pressing enter.
 * 1. Split the current node into two nodes.
 * 2. Insert a new node after the current node.
 * 3. Move the children of the current node to the new node if needed.
 */
export const enterActionForBlockThunk = createAsyncThunk(
  'document/insertNodeByEnter',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const node = state.document.nodes[id];
    const caret = state.documentRange.caret;
    if (!node || !caret || caret.id !== id) return;

    const nodeDelta = new Delta(node.data.delta).slice(0, caret.index);
    const insertNodeDelta = new Delta(node.data.delta).slice(caret.index + caret.length);

    const insertNodeAction = getInsertEnterNodeAction(node, insertNodeDelta, controller);
    if (!insertNodeAction) return;
    const updateNode = {
      ...node,
      data: {
        ...node.data,
        delta: nodeDelta.ops,
      },
    };

    const children = state.document.children[node.children];
    const needMoveChildren = blockConfig[node.type].splitProps?.nextLineRelationShip === SplitRelationship.NextSibling;
    console.log('needMoveChildren', needMoveChildren);
    const moveChildrenAction = needMoveChildren
      ? controller.getMoveChildrenAction(
          children.map((id) => state.document.nodes[id]),
          insertNodeAction.id,
          ''
        )
      : [];
    const actions = [insertNodeAction.action, controller.getUpdateAction(updateNode), ...moveChildrenAction];
    await controller.applyActions(actions);

    dispatch(rangeActions.clearRange());
    dispatch(
      rangeActions.setCaret({
        id: insertNodeAction.id,
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
  async (payload: { id: string; down?: boolean }, thunkAPI) => {
    const { id, down } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const rangeState = state.documentRange;
    const caret = rangeState.caret;
    const node = state.document.nodes[id];
    if (!node || !caret || id !== caret.id) return;

    let newCaret;

    if (down) {
      newCaret = transformToNextLineCaret(state.document, caret);
    } else {
      newCaret = transformToPrevLineCaret(state.document, caret);
    }
    if (!newCaret) {
      return;
    }
    dispatch(rangeActions.setCaret(newCaret));
  }
);

export const leftActionForBlockThunk = createAsyncThunk(
  'document/leftActionForBlock',
  async (payload: { id: string }, thunkAPI) => {
    const { id } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const rangeState = state.documentRange;
    const caret = rangeState.caret;
    const node = state.document.nodes[id];
    if (!node || !caret || id !== caret.id) return;
    let newCaret;
    if (caret.length > 0) {
      newCaret = {
        id,
        index: caret.index,
        length: 0,
      };
    } else {
      if (caret.index > 0) {
        newCaret = {
          id,
          index: caret.index - 1,
          length: 0,
        };
      } else {
        const prevNode = findPrevHasDeltaNode(state.document, id);
        if (!prevNode) return;
        const prevDelta = new Delta(prevNode.data.delta);
        newCaret = {
          id: prevNode.id,
          index: prevDelta.length(),
          length: 0,
        };
      }
    }

    if (!newCaret) {
      return;
    }
    dispatch(rangeActions.setCaret(newCaret));
  }
);

export const rightActionForBlockThunk = createAsyncThunk(
  'document/rightActionForBlock',
  async (payload: { id: string }, thunkAPI) => {
    const { id } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const rangeState = state.documentRange;
    const caret = rangeState.caret;
    const node = state.document.nodes[id];
    if (!node || !caret || id !== caret.id) return;
    let newCaret;
    const delta = new Delta(node.data.delta);
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
        const nextNode = findNextHasDeltaNode(state.document, id);
        if (!nextNode) return;
        newCaret = {
          id: nextNode.id,
          index: 0,
          length: 0,
        };
      }
    }

    if (!newCaret) {
      return;
    }
    dispatch(rangeActions.setCaret(newCaret));
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
    },
    thunkAPI
  ) => {
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const rangeState = state.documentRange;
    let caret;
    const leftCaret = getLeftCaretByRange(rangeState);
    const rightCaret = getRightCaretByRange(rangeState);

    if (!leftCaret || !rightCaret) return;

    switch (payload.key) {
      case Keyboard.keys.LEFT:
        caret = leftCaret;
        break;
      case Keyboard.keys.RIGHT:
        caret = rightCaret;
        break;
      case Keyboard.keys.UP:
        caret = transformToPrevLineCaret(state.document, leftCaret);
        break;
      case Keyboard.keys.DOWN:
        caret = transformToNextLineCaret(state.document, rightCaret);
        break;
    }
    if (!caret) return;
    dispatch(rangeActions.clearRange());
    dispatch(rangeActions.setCaret(caret));
  }
);

import { createAsyncThunk } from "@reduxjs/toolkit";
import { DocumentController } from "$app/stores/effects/document/document_controller";
import { BlockType, RangeStatic, SplitRelationship } from "$app/interfaces/document";
import { turnToTextBlockThunk } from "$app_reducers/document/async-actions/turn_to";
import {
  findNextHasDeltaNode,
  findPrevHasDeltaNode,
  getInsertEnterNodeAction,
  getLeftCaretByRange,
  getRightCaretByRange,
  transformToNextLineCaret,
  transformToPrevLineCaret
} from "$app/utils/document/action";
import Delta from "quill-delta";
import { indentNodeThunk, mergeDeltaThunk, outdentNodeThunk } from "$app_reducers/document/async-actions/blocks";
import { rangeActions } from "$app_reducers/document/slice";
import { RootState } from "$app/stores/store";
import { blockConfig } from "$app/constants/document/config";
import { Keyboard } from "$app/constants/document/keyboard";
import { DOCUMENT_NAME, RANGE_NAME } from "$app/constants/document/name";
import { getDeltaText, getPreviousWordIndex } from "$app/utils/document/delta";
import { updatePageName } from "$app_reducers/pages/async_actions";
import { newBlock } from "$app/utils/document/block";


/**
 - Deletes a block using the backspace or delete key.
 - If the block is not a text block, it is converted into a text block.
 - If the block is a text block:
 - - If the block is the first line, it is merged into the document title, and a new line is inserted.
 - - If the block is not the first line and it has a next sibling, it is merged into the previous line (including the previous sibling and its parent).
 - - If the block has no next sibling and is not a top-level block, it is outdented (moved to a higher level in the hierarchy).
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
    const isFirstLine = isTopLevel && index === 0;

    if (isTopLevel && isFirstLine) {
      // merge to document title and insert a new line
      const parentDelta = new Delta(parent.data.delta);
      const caretIndex = parentDelta.length();
      const caret = {
        id: parent.id,
        index: caretIndex,
        length: 0,
      };
      const titleDelta = parentDelta.concat(new Delta(node.data.delta));
      await dispatch(updatePageName({ id: docId, name: getDeltaText(titleDelta) }));
      const actions = [
        controller.getDeleteAction(node),
      ]

      if (!nextNodeId) {
        // insert a new line
        const block = newBlock<any>(BlockType.TextBlock, parent.id, {
          delta: [{ insert: "" }]
        });
        actions.push(controller.getInsertAction(block, null));
      }
      await controller.applyActions(actions);
      dispatch(rangeActions.initialState(docId));
      dispatch(
        rangeActions.setCaret({
          docId,
          caret,
        })
      );
      return;
    }
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
      dispatch(rangeActions.initialState(docId));
      dispatch(
        rangeActions.setCaret({
          docId,
          caret,
        })
      );
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
    const docId = controller.documentId;
    const documentState = state[DOCUMENT_NAME][docId];
    const node = documentState.nodes[id];
    const caret = state[RANGE_NAME][docId]?.caret;

    if (!node || !caret || caret.id !== id) return;
    const delta = new Delta(node.data.delta);

    const nodeDelta = delta.slice(0, caret.index);

    const insertNodeDelta = new Delta(node.data.delta).slice(caret.index + caret.length);

    const isDocumentTitle = !node.parent;
    // update page title and insert a new line
    if (isDocumentTitle) {
      // update page title
      await dispatch(updatePageName({
        id: docId,
        name: getDeltaText(nodeDelta),
      }));
      // insert a new line
      const block = newBlock<any>(BlockType.TextBlock, node.id, {
        delta: insertNodeDelta.ops,
      });
      const insertNodeAction = controller.getInsertAction(block, null);
      await controller.applyActions([insertNodeAction]);
      dispatch(rangeActions.initialState(docId));
      dispatch(
        rangeActions.setCaret({
          docId,
          caret: {
            id: block.id,
            index: 0,
            length: 0,
          },
        })
      );
      return;
    }

    if (delta.length() === 0 && node.type !== BlockType.TextBlock) {
      // If the node is not a text block, turn it to a text block
      await dispatch(turnToTextBlockThunk({ id, controller }));
      return;
    }


    const insertNodeAction = getInsertEnterNodeAction(node, insertNodeDelta, controller);

    if (!insertNodeAction) return;

    const updateNode = {
      ...node,
      data: {
        ...node.data,
        delta: nodeDelta.ops,
      },
    };

    const children = documentState.children[node.children];
    const needMoveChildren = blockConfig[node.type].splitProps?.nextLineRelationShip === SplitRelationship.NextSibling;
    const moveChildrenAction = needMoveChildren
      ? controller.getMoveChildrenAction(
          children.map((id) => documentState.nodes[id]),
          insertNodeAction.id,
          ''
        )
      : [];
    const actions = [insertNodeAction.action, controller.getUpdateAction(updateNode), ...moveChildrenAction];

    await controller.applyActions(actions);

    dispatch(rangeActions.initialState(docId));
    dispatch(
      rangeActions.setCaret({
        docId,
        caret: {
          id: insertNodeAction.id,
          index: 0,
          length: 0,
        },
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

    if (caret.length > 0) {
      newCaret = {
        id,
        index: caret.index,
        length: 0,
      };
    } else {
      if (caret.index > 0) {
        const delta = new Delta(node.data.delta);
        const newIndex = getPreviousWordIndex(delta, caret.index);

        newCaret = {
          id,
          index: newIndex,
          length: 0,
        };
      } else {
        const prevNode = findPrevHasDeltaNode(documentState, id);

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
        const nextNode = findNextHasDeltaNode(documentState, id);

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

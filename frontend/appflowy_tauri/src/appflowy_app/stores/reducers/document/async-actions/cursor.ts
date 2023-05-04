import { createAsyncThunk } from '@reduxjs/toolkit';
import { documentActions } from '../slice';
import { DocumentState, TextSelection } from '$app/interfaces/document';
import { Editor } from 'slate';
import {
  getBeforeRangeAt,
  getEndLineSelectionByOffset,
  getLastLineOffsetByDelta,
  getNodeBeginSelection,
  getNodeEndSelection,
  getStartLineSelectionByOffset,
} from '$app/utils/document/blocks/text/delta';
import { getNextLineId, getPrevLineId } from '$app/utils/document/blocks/common';

export const setCursorBeforeThunk = createAsyncThunk(
  'document/setCursorBefore',
  async (payload: { id: string }, thunkAPI) => {
    const { id } = payload;
    const { dispatch } = thunkAPI;
    const selection = getNodeBeginSelection();
    dispatch(documentActions.setTextSelection({ blockId: id, selection }));
  }
);

export const setCursorAfterThunk = createAsyncThunk(
  'document/setCursorAfter',
  async (payload: { id: string }, thunkAPI) => {
    const { id } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const selection = getNodeEndSelection(node.data.delta);
    dispatch(documentActions.setTextSelection({ blockId: node.id, selection }));
  }
);

export const setCursorPreLineThunk = createAsyncThunk(
  'document/setCursorPreLine',
  async (payload: { id: string; editor: Editor; focusEnd?: boolean }, thunkAPI) => {
    const { id, editor, focusEnd } = payload;
    const selection = editor.selection as TextSelection;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const prevId = getPrevLineId(state, id);
    if (!prevId) return;

    let prevLineNode = state.nodes[prevId];
    // Find the prev line that has delta
    while (!prevLineNode.data.delta) {
      const id = getPrevLineId(state, prevId);
      if (!id) return;
      prevLineNode = state.nodes[id];
    }

    // whatever the selection is, set cursor to the end of prev line when focusEnd is true
    if (focusEnd) {
      await dispatch(setCursorAfterThunk({ id: prevLineNode.id }));
      return;
    }

    const range = getBeforeRangeAt(editor, selection);
    const textOffset = Editor.string(editor, range).length;

    // set the cursor to prev line with the relative offset
    const newSelection = getEndLineSelectionByOffset(prevLineNode.data.delta, textOffset);
    dispatch(documentActions.setTextSelection({ blockId: prevLineNode.id, selection: newSelection }));
  }
);

export const setCursorNextLineThunk = createAsyncThunk(
  'document/setCursorNextLine',
  async (payload: { id: string; editor: Editor; focusStart?: boolean }, thunkAPI) => {
    const { id, editor, focusStart } = payload;
    const selection = editor.selection as TextSelection;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    const nextId = getNextLineId(state, id);
    if (!nextId) return;
    let nextLineNode = state.nodes[nextId];
    // Find the next line that has delta
    while (!nextLineNode.data.delta) {
      const id = getNextLineId(state, nextId);
      if (!id) return;
      nextLineNode = state.nodes[id];
    }

    const delta = nextLineNode.data.delta;
    // whatever the selection is, set cursor to the start of next line when focusStart is true
    if (focusStart) {
      await dispatch(setCursorBeforeThunk({ id: nextLineNode.id }));
      return;
    }

    const range = getBeforeRangeAt(editor, selection);
    const textOffset = Editor.string(editor, range).length - getLastLineOffsetByDelta(node.data.delta);

    // set the cursor to next line with the relative offset
    const newSelection = getStartLineSelectionByOffset(delta, textOffset);

    dispatch(documentActions.setTextSelection({ blockId: nextLineNode.id, selection: newSelection }));
  }
);

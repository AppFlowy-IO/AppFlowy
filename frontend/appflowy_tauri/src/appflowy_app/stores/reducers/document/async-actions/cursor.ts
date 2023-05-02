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
} from '$app/utils/document/slate/text';
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
    const prevLineNode = state.nodes[prevId];

    // if prev line have no delta, just set block is selected
    if (!prevLineNode.data.delta) {
      dispatch(documentActions.setSelectionById(prevId));
      return;
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
    const nextLineNode = state.nodes[nextId];
    const delta = nextLineNode.data.delta;
    // if next line have no delta, just set block is selected
    if (!delta) {
      dispatch(documentActions.setSelectionById(nextId));
      return;
    }

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

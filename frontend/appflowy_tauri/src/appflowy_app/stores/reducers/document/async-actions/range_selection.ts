import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentState, TextSelection } from '$app/interfaces/document';
import { rangeSelectionActions } from '$app_reducers/document/slice';
import { getNodeBeginSelection, getNodeEndSelection } from '$app/utils/document/blocks/text/delta';
import { isEqual } from '$app/utils/tool';
import { RootState } from '$app/stores/store';
import { getNodesInRange } from '$app/utils/document/blocks/common';

const amendAnchorNodeThunk = createAsyncThunk(
  'document/amendAnchorNode',
  async (
    payload: {
      id: string;
    },
    thunkAPI
  ) => {
    const { id } = payload;
    const { getState, dispatch } = thunkAPI;
    const nodes = (getState() as { document: DocumentState }).document.nodes;

    const state = getState() as RootState;
    const { isDragging, isForward, ...range } = state.documentRangeSelection;
    const { anchor: anchorNode, focus: focusNode } = range;

    if (!isDragging || !anchorNode || anchorNode.id !== id) return;
    const isCollapsed = focusNode?.id === id && anchorNode?.id === id;
    if (isCollapsed) return;

    const selection = anchorNode.selection;
    const node = nodes[id];
    const focus = isForward ? getNodeEndSelection(node.data.delta).anchor : getNodeBeginSelection().anchor;
    if (isEqual(focus, selection.focus)) return;
    const newSelection = {
      anchor: selection.anchor,
      focus,
    };

    dispatch(
      rangeSelectionActions.setRange({
        anchor: {
          id,
          selection: newSelection as TextSelection,
        },
      })
    );
  }
);

export const syncRangeSelectionThunk = createAsyncThunk(
  'document/syncRangeSelection',
  async (
    payload: {
      id: string;
      selection: TextSelection;
    },
    thunkAPI
  ) => {
    const { getState, dispatch } = thunkAPI;
    const state = getState() as RootState;
    const range = state.documentRangeSelection;
    const isDragging = range.isDragging;

    const { id, selection } = payload;

    const updateRange = {
      focus: {
        id,
        selection,
      },
    };

    if (!isDragging && range.anchor?.id === id) {
      Object.assign(updateRange, {
        anchor: {
          id,
          selection: { ...selection },
        },
      });
      dispatch(rangeSelectionActions.setRange(updateRange));
      return;
    }
    if (!range.anchor || range.anchor.id === id) {
      Object.assign(updateRange, {
        anchor: {
          id,
          selection: {
            anchor: !range.anchor ? selection.anchor : range.anchor.selection.anchor,
            focus: selection.focus,
          },
        },
      });
    }

    dispatch(rangeSelectionActions.setRange(updateRange));

    const anchorId = range.anchor?.id;
    // more than one node is selected
    if (anchorId && anchorId !== id) {
      dispatch(amendAnchorNodeThunk({ id: anchorId }));
    }
  }
);

export const setRangeSelectionThunk = createAsyncThunk('document/setRangeSelection', async (payload, thunkAPI) => {
  const { getState, dispatch } = thunkAPI;
  const state = getState() as RootState;
  const { anchor, focus, isForward } = state.documentRangeSelection;
  const document = state.document;
  if (!anchor || !focus || isForward === undefined) return;
  const rangeIds = getNodesInRange(
    {
      startId: anchor.id,
      endId: focus.id,
    },
    isForward,
    document
  );
  dispatch(rangeSelectionActions.setSelection(rangeIds));
});

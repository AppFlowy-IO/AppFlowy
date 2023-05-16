import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentState, RangeSelectionState, TextSelection } from '$app/interfaces/document';
import { rangeSelectionActions } from '$app_reducers/document/slice';
import { getNodeEndSelection, selectionIsForward } from '$app/utils/document/blocks/text/delta';
import { isEqual } from '$app/utils/tool';

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
    const range = (getState() as { documentRangeSelection: RangeSelectionState }).documentRangeSelection;
    const { anchor: anchorNode, isDragging, focus: focusNode } = range;

    if (!isDragging || !anchorNode || anchorNode.id !== id) return;
    const isCollapsed = focusNode?.id === id && anchorNode?.id === id;
    if (isCollapsed) return;

    const selection = anchorNode.selection;
    const isForward = selectionIsForward(selection);
    const node = nodes[id];
    const focus = isForward
      ? getNodeEndSelection(node.data.delta).anchor
      : {
          path: [0, 0],
          offset: 0,
        };
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
    const range = (getState() as { documentRangeSelection: RangeSelectionState }).documentRangeSelection;

    const { id, selection } = payload;
    const updateRange = {
      focus: {
        id,
        selection,
      },
    };
    const isAnchor = range.anchor?.id === id;
    if (isAnchor) {
      Object.assign(updateRange, {
        anchor: {
          id,
          selection,
        },
      });
    }
    dispatch(rangeSelectionActions.setRange(updateRange));

    const anchorId = range.anchor?.id;
    if (!isAnchor && anchorId) {
      dispatch(amendAnchorNodeThunk({ id: anchorId }));
    }
  }
);

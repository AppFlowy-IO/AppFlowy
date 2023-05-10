import { DocumentState, Node, RangeSelectionState } from '@/appflowy_app/interfaces/document';
import { BlockEventPayloadPB } from '@/services/backend';
import { createSlice, PayloadAction } from "@reduxjs/toolkit";
import { parseValue, matchChange } from '$app/utils/document/subscribe';

const initialState: DocumentState = {
  nodes: {},
  children: {},
};

const rectSelectionInitialState: string[] = [];

const rangeSelectionInitialState: RangeSelectionState = {};

export const documentSlice = createSlice({
  name: 'document',
  initialState: initialState,
  // Here we can't offer actions to update the document state.
  // Because the document state is updated by the `onDataChange`
  reducers: {
    // initialize the document
    clear: () => {
      return initialState;
    },

    // set document data
    create: (
      state,
      action: PayloadAction<{
        nodes: Record<string, Node>;
        children: Record<string, string[]>;
      }>
    ) => {
      const { nodes, children } = action.payload;
      state.nodes = nodes;
      state.children = children;
    },

    /**
     This function listens for changes in the data layer triggered by the data API,
     and updates the UI state accordingly.
     It enables a unidirectional data flow,
     where changes in the data layer update the UI layer,
     but not the other way around.
     */
    onDataChange: (
      state,
      action: PayloadAction<{
        data: BlockEventPayloadPB;
        isRemote: boolean;
      }>
    ) => {
      const { path, id, value, command } = action.payload.data;

      const valueJson = parseValue(value);
      if (!valueJson) return;

      // match change
      matchChange(state, { path, id, value: valueJson, command });
    },
  },
});

export const rectSelectionSlice = createSlice({
  name: 'documentRectSelection',
  initialState: rectSelectionInitialState,
  reducers: {
    // update block selections
    updateSelections: (state, action: PayloadAction<string[]>) => {
      return action.payload;
    },

    // set block selected
    setSelectionById: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      if (state.includes(id)) return;
      state.push(id);
    },
  }
});


export const rangeSelectionSlice = createSlice({
  name: 'documentRangeSelection',
  initialState: rangeSelectionInitialState,
  reducers: {
    setRange: (
      state,
      action: PayloadAction<RangeSelectionState>
    ) => {
      state.anchor = action.payload.anchor;
      state.focus = action.payload.focus;
    },

    clearRange: (state, _: PayloadAction) => {
      state.anchor = undefined;
      state.focus = undefined;
    },
  }
});

export const documentReducers = {
  [documentSlice.name]: documentSlice.reducer,
  [rectSelectionSlice.name]: rectSelectionSlice.reducer,
  [rangeSelectionSlice.name]: rangeSelectionSlice.reducer,
};

export const documentActions = documentSlice.actions;
export const rectSelectionActions = rectSelectionSlice.actions;
export const rangeSelectionActions = rangeSelectionSlice.actions;
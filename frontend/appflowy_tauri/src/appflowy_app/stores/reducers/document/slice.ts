import { DocumentState, Node, RangeSelectionState } from '@/appflowy_app/interfaces/document';
import { BlockEventPayloadPB } from '@/services/backend';
import { combineReducers, createSlice, PayloadAction } from "@reduxjs/toolkit";
import { parseValue, matchChange } from '$app/utils/document/subscribe';
import blockSelection from "$app/components/document/BlockSelection";
import { databaseSlice } from "$app_reducers/database/slice";

const initialState: DocumentState = {
  nodes: {},
  children: {},
};

const rectSelectionInitialState: {
  selections: string[];
} = {
  selections: [],
};

const rangeSelectionInitialState: RangeSelectionState = {};

export const documentSlice = createSlice({
  name: 'document',
  initialState: initialState,
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

    // We need this action to update the local state before `onDataChange` to make the UI more smooth,
    // because we often use `debounce` to send the change to db, so the db data will be updated later.
    updateNodeData: (state, action: PayloadAction<{ id: string; data: Record<string, any> }>) => {
      const { id, data } = action.payload;
      const node = state.nodes[id];
      if (!node) return;
      node.data = {
        ...node.data,
        ...data,
      };
    },

    // when we use `onDataChange` to handle the change, we don't need care about the change is from which client,
    // because the data is always from db state, and then to UI.
    // Except the `updateNodeData` action, we will use it before `onDataChange` to update the local state,
    // so we should skip update block's `data` field when the change is from local
    onDataChange: (
      state,
      action: PayloadAction<{
        data: BlockEventPayloadPB;
        isRemote: boolean;
      }>
    ) => {
      const { path, id, value, command } = action.payload.data;
      const isRemote = action.payload.isRemote;

      const valueJson = parseValue(value);
      if (!valueJson) return;

      // match change
      matchChange(state, { path, id, value: valueJson, command }, isRemote);
    },
  },
});

export const rectSelectionSlice = createSlice({
  name: 'rectSelection',
  initialState: rectSelectionInitialState,
  reducers: {
    // update block selections
    updateSelections: (state, action: PayloadAction<string[]>) => {
      state.selections = action.payload;
    },

    // set block selected
    setSelectionById: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      state.selections = [id];
    },
  }
});


export const rangeSelectionSlice = createSlice({
  name: 'rangeSelection',
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
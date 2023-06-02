import {
  DocumentState,
  Node,
  RectSelectionState,
  SlashCommandState,
  RangeState,
  RangeStatic,
} from '@/appflowy_app/interfaces/document';
import { BlockEventPayloadPB } from '@/services/backend';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { parseValue, matchChange } from '$app/utils/document/subscribe';

const initialState: DocumentState = {
  nodes: {},
  children: {},
};

const rectSelectionInitialState: RectSelectionState = {
  selection: [],
  isDragging: false,
};

const rangeInitialState: RangeState = {
  isDragging: false,
  ranges: {},
};

const slashCommandInitialState: SlashCommandState = {
  isSlashCommand: false,
};

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
      state.selection = action.payload;
    },

    // set block selected
    setSelectionById: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      if (state.selection.includes(id)) return;
      state.selection = [...state.selection, id];
    },

    setDragging: (state, action: PayloadAction<boolean>) => {
      state.isDragging = action.payload;
    },
  },
});

export const rangeSlice = createSlice({
  name: 'documentRange',
  initialState: rangeInitialState,
  reducers: {
    setRanges: (state, action: PayloadAction<RangeState['ranges']>) => {
      state.ranges = action.payload;
    },
    setRange: (
      state,
      action: PayloadAction<{
        id: string;
        rangeStatic: {
          index: number;
          length: number;
        };
      }>
    ) => {
      const { id, rangeStatic } = action.payload;
      state.ranges[id] = rangeStatic;
    },
    removeRange: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      delete state.ranges[id];
    },
    setAnchorPoint: (
      state,
      action: PayloadAction<{
        id: string;
        point: { x: number; y: number };
      }>
    ) => {
      state.anchor = action.payload;
    },
    setAnchorPointRange: (
      state,
      action: PayloadAction<{
        index: number;
        length: number;
      }>
    ) => {
      const anchor = state.anchor;
      if (!anchor) return;
      anchor.point = {
        ...anchor.point,
        ...action.payload,
      };
    },
    setFocusPoint: (
      state,
      action: PayloadAction<{
        id: string;
        point: { x: number; y: number };
      }>
    ) => {
      state.focus = action.payload;
    },
    setDragging: (state, action: PayloadAction<boolean>) => {
      state.isDragging = action.payload;
    },
    setCaret: (state, action: PayloadAction<RangeStatic>) => {
      const id = action.payload.id;
      state.ranges[id] = {
        index: action.payload.index,
        length: action.payload.length,
      };
      state.caret = action.payload;
    },
    clearRange: (state, _: PayloadAction) => {
      state.isDragging = false;
      state.ranges = {};
      state.anchor = undefined;
      state.focus = undefined;
    },
  },
});
export const slashCommandSlice = createSlice({
  name: 'documentSlashCommand',
  initialState: slashCommandInitialState,
  reducers: {
    openSlashCommand: (
      state,
      action: PayloadAction<{
        blockId: string;
      }>
    ) => {
      const { blockId } = action.payload;
      return {
        ...state,
        isSlashCommand: true,
        blockId,
      };
    },
    closeSlashCommand: (state, _: PayloadAction) => {
      return slashCommandInitialState;
    },
  },
});

export const documentReducers = {
  [documentSlice.name]: documentSlice.reducer,
  [rectSelectionSlice.name]: rectSelectionSlice.reducer,
  [rangeSlice.name]: rangeSlice.reducer,
  [slashCommandSlice.name]: slashCommandSlice.reducer,
};

export const documentActions = documentSlice.actions;
export const rectSelectionActions = rectSelectionSlice.actions;
export const rangeActions = rangeSlice.actions;
export const slashCommandActions = slashCommandSlice.actions;

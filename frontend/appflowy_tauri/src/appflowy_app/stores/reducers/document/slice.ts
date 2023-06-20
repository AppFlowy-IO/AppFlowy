import {
  DocumentState,
  Node,
  RectSelectionState,
  SlashCommandState,
  RangeState,
  RangeStatic,
  LinkPopoverState,
  SlashCommandOption,
} from '@/appflowy_app/interfaces/document';
import { BlockEventPayloadPB } from '@/services/backend';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { parseValue, matchChange } from '$app/utils/document/subscribe';

const initialState: Record<string, DocumentState> = {};

const rectSelectionInitialState: Record<string, RectSelectionState> = {};

const rangeInitialState: Record<string, RangeState> = {};

const slashCommandInitialState: Record<string, SlashCommandState> = {};

const linkPopoverState: Record<string, LinkPopoverState> = {};

export const documentSlice = createSlice({
  name: 'document',
  initialState: initialState,
  // Here we can't offer actions to update the document state.
  // Because the document state is updated by the `onDataChange`
  reducers: {
    // initialize the document
    initialState: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      state[docId] = {
        nodes: {},
        children: {},
      };
    },
    clear: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      delete state[docId];
    },

    // set document data
    create: (
      state,
      action: PayloadAction<{
        docId: string;
        nodes: Record<string, Node>;
        children: Record<string, string[]>;
      }>
    ) => {
      const { docId, nodes, children } = action.payload;

      state[docId] = {
        nodes,
        children,
      };
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
        docId: string;
        data: BlockEventPayloadPB;
        isRemote: boolean;
      }>
    ) => {
      const { docId, data } = action.payload;
      const { path, id, value, command } = data;

      const documentState = state[docId];

      if (!documentState) return;
      const valueJson = parseValue(value);

      if (!valueJson) return;

      // match change
      matchChange(documentState, { path, id, value: valueJson, command });
    },
  },
});

export const rectSelectionSlice = createSlice({
  name: 'documentRectSelection',
  initialState: rectSelectionInitialState,
  reducers: {
    initialState: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      state[docId] = {
        selection: [],
        isDragging: false,
      };
    },
    clear: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      delete state[docId];
    },
    // update block selections
    updateSelections: (
      state,
      action: PayloadAction<{
        docId: string;
        selection: string[];
      }>
    ) => {
      const { docId, selection } = action.payload;

      state[docId].selection = selection;
    },

    // set block selected
    setSelectionById: (
      state,
      action: PayloadAction<{
        docId: string;
        blockId: string;
      }>
    ) => {
      const { docId, blockId } = action.payload;
      const selection = state[docId].selection;

      if (selection.includes(blockId)) return;
      state[docId].selection = [...selection, blockId];
    },

    setDragging: (
      state,
      action: PayloadAction<{
        docId: string;
        isDragging: boolean;
      }>
    ) => {
      const { docId, isDragging } = action.payload;

      state[docId].isDragging = isDragging;
    },
  },
});

export const rangeSlice = createSlice({
  name: 'documentRange',
  initialState: rangeInitialState,
  reducers: {
    initialState: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      state[docId] = {
        isDragging: false,
        ranges: {},
      };
    },
    clear: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      delete state[docId];
    },
    setRanges: (
      state,
      action: PayloadAction<{
        docId: string;
        ranges: RangeState['ranges'];
      }>
    ) => {
      const { docId, ranges } = action.payload;

      state[docId].ranges = ranges;
    },
    setRange: (
      state,
      action: PayloadAction<{
        docId: string;
        id: string;
        rangeStatic: {
          index: number;
          length: number;
        };
      }>
    ) => {
      const { docId, id, rangeStatic } = action.payload;

      state[docId].ranges[id] = rangeStatic;
    },
    removeRange: (
      state,
      action: PayloadAction<{
        docId: string;
        id: string;
      }>
    ) => {
      const { docId, id } = action.payload;
      const ranges = state[docId].ranges;

      delete ranges[id];
    },
    setAnchorPoint: (
      state,
      action: PayloadAction<{
        docId: string;
        id: string;
        point: { x: number; y: number };
      }>
    ) => {
      const { docId, id, point } = action.payload;

      state[docId].anchor = {
        id,
        point,
      };
    },
    setAnchorPointRange: (
      state,
      action: PayloadAction<{
        docId: string;
        index: number;
        length: number;
      }>
    ) => {
      const { docId, index, length } = action.payload;
      const anchor = state[docId].anchor;

      if (!anchor) return;
      anchor.point = {
        ...anchor.point,
        index,
        length,
      };
    },
    setFocusPoint: (
      state,
      action: PayloadAction<{
        docId: string;
        id: string;
        point: { x: number; y: number };
      }>
    ) => {
      const { docId, id, point } = action.payload;

      state[docId].focus = {
        id,
        point,
      };
    },
    setDragging: (
      state,
      action: PayloadAction<{
        docId: string;
        isDragging: boolean;
      }>
    ) => {
      const { docId, isDragging } = action.payload;

      state[docId].isDragging = isDragging;
    },
    setCaret: (
      state,
      action: PayloadAction<{
        docId: string;
        caret: RangeStatic | null;
      }>
    ) => {
      const { docId, caret } = action.payload;
      const rangeState = state[docId];

      if (!caret) {
        rangeState.caret = undefined;
        return;
      }

      const { id, index, length } = caret;

      rangeState.ranges[id] = {
        index,
        length,
      };
      rangeState.caret = caret;
    },
    clearRanges: (
      state,
      action: PayloadAction<{
        docId: string;
        exclude?: string;
      }>
    ) => {
      const { docId, exclude } = action.payload;
      const ranges = state[docId].ranges;
      const newRanges = Object.keys(ranges).reduce((acc, id) => {
        if (id !== exclude) return { ...acc };
        return {
          ...acc,
          [id]: ranges[id],
        };
      }, {});

      state[docId].ranges = newRanges;
    },
  },
});

export const slashCommandSlice = createSlice({
  name: 'documentSlashCommand',
  initialState: slashCommandInitialState,
  reducers: {
    initialState: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      state[docId] = {
        isSlashCommand: false,
      };
    },
    clear: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      delete state[docId];
    },
    openSlashCommand: (
      state,
      action: PayloadAction<{
        docId: string;
        blockId: string;
      }>
    ) => {
      const { blockId, docId } = action.payload;

      state[docId] = {
        ...state[docId],
        isSlashCommand: true,
        blockId,
      };
    },
    closeSlashCommand: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      state[docId] = {
        ...state[docId],
        isSlashCommand: false,
      };
    },
    setHoverOption: (
      state,
      action: PayloadAction<{
        docId: string;
        option: SlashCommandOption;
      }>
    ) => {
      const { docId, option } = action.payload;

      state[docId] = {
        ...state[docId],
        hoverOption: option,
      };
    },
  },
});

export const linkPopoverSlice = createSlice({
  name: 'documentLinkPopover',
  initialState: linkPopoverState,
  reducers: {
    initialState: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      state[docId] = {
        open: false,
      };
    },
    clear: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      delete state[docId];
    },
    setLinkPopover: (
      state,
      action: PayloadAction<{
        docId: string;
        linkState: LinkPopoverState;
      }>
    ) => {
      const { docId, linkState } = action.payload;

      state[docId] = linkState;
    },
    updateLinkPopover: (
      state,
      action: PayloadAction<{
        docId: string;
        linkState: LinkPopoverState;
      }>
    ) => {
      const { docId, linkState } = action.payload;
      const { id } = linkState;

      if (!state[docId].open || state[docId].id !== id) return;
      state[docId] = linkState;
    },
    closeLinkPopover: (state, action: PayloadAction<string>) => {
      const docId = action.payload;

      state[docId].open = false;
    },
  },
});

export const documentReducers = {
  [documentSlice.name]: documentSlice.reducer,
  [rectSelectionSlice.name]: rectSelectionSlice.reducer,
  [rangeSlice.name]: rangeSlice.reducer,
  [slashCommandSlice.name]: slashCommandSlice.reducer,
  [linkPopoverSlice.name]: linkPopoverSlice.reducer,
};

export const documentActions = documentSlice.actions;
export const rectSelectionActions = rectSelectionSlice.actions;
export const rangeActions = rangeSlice.actions;
export const slashCommandActions = slashCommandSlice.actions;
export const linkPopoverActions = linkPopoverSlice.actions;

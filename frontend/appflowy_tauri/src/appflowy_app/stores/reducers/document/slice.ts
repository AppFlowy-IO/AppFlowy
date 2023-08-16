import {
  DocumentState,
  Node,
  RectSelectionState,
  SlashCommandState,
  RangeState,
  RangeStatic,
  SlashCommandOption,
} from '@/appflowy_app/interfaces/document';
import { BlockEventPayloadPB } from '@/services/backend';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { parseValue, matchChange } from '$app/utils/document/subscribe';
import { temporarySlice } from '$app_reducers/document/temporary_slice';
import { DOCUMENT_NAME, RANGE_NAME, RECT_RANGE_NAME, SLASH_COMMAND_NAME } from '$app/constants/document/name';
import { blockEditSlice } from '$app_reducers/document/block_edit_slice';
import { Op } from 'quill-delta';
import { mentionSlice } from '$app_reducers/document/mention_slice';
import { copyText } from '$app/utils/document/copy_paste';
import { generateId } from '$app/utils/document/block';

const initialState: Record<string, DocumentState> = {};

const rectSelectionInitialState: Record<string, RectSelectionState> = {};

const rangeInitialState: Record<string, RangeState> = {};

const slashCommandInitialState: Record<string, SlashCommandState> = {};

export const documentSlice = createSlice({
  name: DOCUMENT_NAME,
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
        deltaMap: {},
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
        deltaMap: Record<string, string>;
      }>
    ) => {
      const { docId, nodes, children, deltaMap } = action.payload;

      copyText(
        JSON.stringify({
          nodes,
          children,
          deltaMap,
        })
      );
      state[docId] = {
        nodes,
        children,
        deltaMap,
      };
    },

    updateRootNodeDelta: (
      state,
      action: PayloadAction<{
        docId: string;
        rootId: string;
        delta: Op[];
      }>
    ) => {
      const { docId, delta, rootId } = action.payload;
      const documentState = state[docId];

      if (!documentState) return;
      const rootNode = documentState.nodes[rootId];

      if (!rootNode) return;
      let externalId = rootNode.externalId;

      if (!externalId) externalId = generateId();
      rootNode.externalId = externalId;
      documentState.deltaMap[externalId] = JSON.stringify(delta);
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
  name: RECT_RANGE_NAME,
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
  name: RANGE_NAME,
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
        anchorPoint?: {
          id: string;
          point: { x: number; y: number };
        };
      }>
    ) => {
      const { docId, anchorPoint } = action.payload;

      if (anchorPoint) {
        state[docId].anchor = { ...anchorPoint };
      } else {
        delete state[docId].anchor;
      }
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
        focusPoint?: {
          id: string;
          point: { x: number; y: number };
        };
      }>
    ) => {
      const { docId, focusPoint } = action.payload;

      if (focusPoint) {
        state[docId].focus = { ...focusPoint };
      } else {
        delete state[docId].focus;
      }
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

      if (!exclude) {
        state[docId].ranges = {};
        return;
      }

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
  name: SLASH_COMMAND_NAME,
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

export const documentReducers = {
  [documentSlice.name]: documentSlice.reducer,
  [rectSelectionSlice.name]: rectSelectionSlice.reducer,
  [rangeSlice.name]: rangeSlice.reducer,
  [slashCommandSlice.name]: slashCommandSlice.reducer,
  [temporarySlice.name]: temporarySlice.reducer,
  [blockEditSlice.name]: blockEditSlice.reducer,
  [mentionSlice.name]: mentionSlice.reducer,
};

export const documentActions = documentSlice.actions;
export const rectSelectionActions = rectSelectionSlice.actions;
export const rangeActions = rangeSlice.actions;
export const slashCommandActions = slashCommandSlice.actions;

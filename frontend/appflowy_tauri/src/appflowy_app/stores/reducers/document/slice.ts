import { DocumentState, Node, TextSelection } from '@/appflowy_app/interfaces/document';
import { BlockEventPayloadPB } from '@/services/backend';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { RegionGrid } from '@/appflowy_app/utils/region_grid';
import { parseValue, matchChange } from '@/appflowy_app/utils/block_change';

const regionGrid = new RegionGrid(50);

const initialState: DocumentState = {
  nodes: {},
  children: {},
  selections: [],
  textSelections: {},
};

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

    // update block selections
    updateSelections: (state, action: PayloadAction<string[]>) => {
      state.selections = action.payload;
    },

    // set block selected
    setSelectionById: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      state.selections = [id];
    },

    // set block selected by selection rect
    setSelectionByRect: (
      state,
      action: PayloadAction<{
        startX: number;
        startY: number;
        endX: number;
        endY: number;
      }>
    ) => {
      const { startX, startY, endX, endY } = action.payload;
      const blocks = regionGrid.getIntersectBlocks(startX, startY, endX, endY);
      state.selections = blocks.map((block) => block.id);
    },

    // update block position
    updateNodePosition: (
      state,
      action: PayloadAction<{
        id: string;
        rect: {
          x: number;
          y: number;
          width: number;
          height: number;
        };
      }>
    ) => {
      const { id, rect } = action.payload;
      const position = {
        id,
        ...rect,
      };
      regionGrid.updateBlock(id, position);
    },

    // update text selections
    setTextSelection: (
      state,
      action: PayloadAction<{
        blockId: string;
        selection?: TextSelection;
      }>
    ) => {
      const { blockId, selection } = action.payload;
      const node = state.nodes[blockId];
      if (!node || !selection) {
        delete state.textSelections[blockId];
      } else {
        state.textSelections = {
          [blockId]: selection,
        };
      }
    },

    // remove text selections
    removeTextSelection: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      if (!state.textSelections[id]) return;
      state.textSelections;
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

export const documentActions = documentSlice.actions;

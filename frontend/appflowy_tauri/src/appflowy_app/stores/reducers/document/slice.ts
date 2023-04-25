import { NestedBlock } from '@/appflowy_app/interfaces/document';
import { blockChangeValue2Node } from '@/appflowy_app/utils/block';
import { Log } from '@/appflowy_app/utils/log';
import { BlockEventPayloadPB, DeltaTypePB } from '@/services/backend';
import { PayloadAction, createSlice } from '@reduxjs/toolkit';
import { RegionGrid } from './region_grid';

export type Node = NestedBlock;

export interface SelectionPoint {
  path: [number, number];
  offset: number;
}

export interface TextSelection {
  anchor: SelectionPoint;
  focus: SelectionPoint;
}

export interface DocumentState {
  // map of block id to block
  nodes: Record<string, Node>;
  // map of block id to children block ids
  children: Record<string, string[]>;
  // selected block ids
  selections: string[];
  // map of block id to text selection
  textSelections: Record<string, TextSelection>;
}

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

      let valueJson;
      try {
        valueJson = JSON.parse(value);
      } catch {
        Log.error('[onDataChange] json parse error', value);
        return;
      }
      if (!valueJson) return;

      if (command === DeltaTypePB.Inserted || command === DeltaTypePB.Updated) {
        // set map key and value ( block map or children map)
        if (path[0] === 'blocks') {
          const block = blockChangeValue2Node(valueJson);
          if (command === DeltaTypePB.Updated && !isRemote) {
            // the `data` from local is already updated in local, so we just need to update other fields
            const node = state.nodes[block.id];
            if (!node || node.parent !== block.parent || node.type !== block.type || node.children !== block.children) {
              state.nodes[block.id] = block;
            }
          } else {
            state.nodes[block.id] = block;
          }
        } else {
          state.children[id] = valueJson;
        }
      } else {
        // remove map key ( block map or children map)
        if (path[0] === 'blocks') {
          if (state.selections.indexOf(id)) {
            state.selections.splice(state.selections.indexOf(id), 1);
          }
          regionGrid.removeBlock(id);
          delete state.textSelections[id];
          delete state.nodes[id];
        } else {
          delete state.children[id];
        }
      }
    },
  },
});

export const documentActions = documentSlice.actions;

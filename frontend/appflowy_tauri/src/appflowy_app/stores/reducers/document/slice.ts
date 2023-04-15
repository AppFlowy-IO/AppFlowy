import { BlockType, NestedBlock, TextDelta } from '@/appflowy_app/interfaces/document';
import { PayloadAction, createSlice } from '@reduxjs/toolkit';
import { RegionGrid } from './region_grid';

export type Node = NestedBlock;

export interface NodeState {
  nodes: Record<string, Node>;
  children: Record<string, string[]>;
  selections: string[];
}

const regionGrid = new RegionGrid(50);

const initialState: NodeState = {
  nodes: {},
  children: {},
  selections: [],
};

export const documentSlice = createSlice({
  name: 'document',
  initialState: initialState,
  reducers: {
    clear: () => {
      return initialState;
    },

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

    updateSelections: (state, action: PayloadAction<string[]>) => {
      state.selections = action.payload;
    },

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

    setBlocks: (state, action: PayloadAction<Node>) => {
      state.nodes[action.payload.id] = action.payload;
    },

    setChildrenMap: (state, action: PayloadAction<{ id: string; childIds: string[] }>) => {
      const { id, childIds } = action.payload;
      state.children[id] = childIds;
    },

    removeBlock(state, action: PayloadAction<string>) {
      const { id } = state.nodes[action.payload];
      regionGrid.removeBlock(id);
      delete state.nodes[id];
    },

    removeChildren(state, action: PayloadAction<string>) {
      delete state.children[action.payload];
    },
  },
});

export const documentActions = documentSlice.actions;

import { BlockType, TextDelta } from "@/appflowy_app/interfaces/document";
import { PayloadAction, createSlice } from "@reduxjs/toolkit";
import { RegionGrid } from "./region_grid";

export interface Node {
  id: string;
  type: BlockType;
  data: {
    text?: string;
    style?: Record<string, any>
  };
  parent: string | null;
  children: string;
}

export interface NodeState {
  nodes: Record<string, Node>;
  children: Record<string, string[]>;
  delta: Record<string, TextDelta[]>;
  selections: string[];
}

const regionGrid = new RegionGrid(50);

const initialState: NodeState = {
  nodes: {},
  children: {},
  delta: {},
  selections: [],
};

export const documentSlice = createSlice({
  name: 'document',
  initialState: initialState,
  reducers: {
    clear: (state, action: PayloadAction) => {
      return initialState;
    },

    createTree: (state, action: PayloadAction<{
      nodes: Record<string, Node>;
      children: Record<string, string[]>;
      delta: Record<string, TextDelta[]>;
    }>) => {
      const { nodes, children, delta } = action.payload;
      state.nodes = nodes;
      state.children = children;
      state.delta = delta;
    },

    updateSelections: (state, action: PayloadAction<string[]>) => {
      state.selections = action.payload;
    },

    changeSelectionByIntersectRect: (state, action: PayloadAction<{
      startX: number;
      startY: number;
      endX: number;
      endY: number
    }>) => {
      const { startX, startY, endX, endY } = action.payload;
      const blocks = regionGrid.getIntersectBlocks(startX, startY, endX, endY);
      state.selections = blocks.map(block => block.id);
    },

    updateNodePosition: (state, action: PayloadAction<{id: string; rect: {
      x: number;
      y: number;
      width: number;
      height: number;
    }}>) => {
      const { id, rect } = action.payload;
      const position = {
        id,
        ...rect
      };
      regionGrid.updateBlock(id, position);
    },

    updateNode: (state, action: PayloadAction<{id: string; type?: BlockType; data?: any }>) => {
      state.nodes[action.payload.id] = {
        ...state.nodes[action.payload.id],
        ...action.payload
      }
    },
    removeNode: (state, action: PayloadAction<string>) => {
      const { children, data, parent } = state.nodes[action.payload];
      if (parent) {
        const index = state.children[state.nodes[parent].children].indexOf(action.payload);
        if (index > -1) {
          state.children[state.nodes[parent].children].splice(index, 1);
        }
      }
      if (children) {
        delete state.children[children];
      }
      if (data && data.text) {
        delete state.delta[data.text];
      }
      delete state.nodes[action.payload];
    },
  },
});

export const documentActions = documentSlice.actions;

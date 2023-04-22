import { BlockType, NestedBlock, TextDelta } from '@/appflowy_app/interfaces/document';
import { PayloadAction, createSlice } from '@reduxjs/toolkit';
import { nanoid } from 'nanoid';
import { DocumentController } from '../../effects/document/document_controller';
import { RegionGrid } from './region_grid';

export type Node = NestedBlock;

export interface DocumentState {
  nodes: Record<string, Node>;
  children: Record<string, string[]>;
  selections: string[];
}

const regionGrid = new RegionGrid(50);

const initialState: DocumentState = {
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

    setSelectionById: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      state.selections = [id];
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

    setBlockMap: (state, action: PayloadAction<Node>) => {
      state.nodes[action.payload.id] = action.payload;
    },

    removeBlockMapKey(state, action: PayloadAction<string>) {
      if (!state.nodes[action.payload]) return;
      const { id } = state.nodes[action.payload];
      regionGrid.removeBlock(id);
      delete state.nodes[id];
    },

    setChildrenMap: (state, action: PayloadAction<{ id: string; childIds: string[] }>) => {
      const { id, childIds } = action.payload;
      state.children[id] = childIds;
    },

    removeChildrenMapKey(state, action: PayloadAction<string>) {
      if (state.children[action.payload]) {
        delete state.children[action.payload];
      }
    },

    insertChild: (state, action: PayloadAction<{ id: string; childId: string; prevId: string | null }>) => {
      const { id, childId, prevId } = action.payload;
      const parent = state.nodes[id];
      const children = state.children[parent.children];
      const index = prevId ? children.indexOf(prevId) + 1 : 0;
      children.splice(index, 0, childId);
    },

    deleteChild: (state, action: PayloadAction<{ id: string; childId: string }>) => {
      const { id, childId } = action.payload;
      const parent = state.nodes[id];
      const children = state.children[parent.children];
      const index = children.indexOf(childId);
      children.splice(index, 1);
    },

    moveNode: (state, action: PayloadAction<{ id: string; newParentId: string; newPrevId: string | null }>) => {
      const { id, newParentId, newPrevId } = action.payload;
      const newParent = state.nodes[newParentId];
      const oldParentId = state.nodes[id].parent;
      if (!oldParentId) return;
      const oldParent = state.nodes[oldParentId];

      state.nodes[id].parent = newParentId;
      const index = state.children[oldParent.children].indexOf(id);
      state.children[oldParent.children].splice(index, 1);

      const newIndex = newPrevId ? state.children[newParent.children].indexOf(newPrevId) + 1 : 0;
      state.children[newParent.children].splice(newIndex, 0, id);
    },
  },
});

export const documentActions = documentSlice.actions;

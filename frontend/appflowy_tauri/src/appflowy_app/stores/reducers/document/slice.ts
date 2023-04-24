import { BlockType, NestedBlock, TextDelta } from '@/appflowy_app/interfaces/document';
import { PayloadAction, createSlice } from '@reduxjs/toolkit';
import { nanoid } from 'nanoid';
import { DocumentController } from '../../effects/document/document_controller';
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

    // insert block
    setBlockMap: (state, action: PayloadAction<Node>) => {
      state.nodes[action.payload.id] = action.payload;
    },

    // update block when `type`, `parent` or `children` changed
    updateBlock: (state, action: PayloadAction<{ id: string; block: NestedBlock }>) => {
      const { id, block } = action.payload;
      const node = state.nodes[id];
      if (!node || node.parent !== block.parent || node.type !== block.type || node.children !== block.children) {
        state.nodes[action.payload.id] = block;
        return;
      }
    },

    // remove block
    removeBlockMapKey(state, action: PayloadAction<string>) {
      if (!state.nodes[action.payload]) return;
      const { id } = state.nodes[action.payload];
      regionGrid.removeBlock(id);
      delete state.nodes[id];
    },

    // set block's relationship with its children
    setChildrenMap: (state, action: PayloadAction<{ id: string; childIds: string[] }>) => {
      const { id, childIds } = action.payload;
      state.children[id] = childIds;
    },

    // remove block's relationship with its children
    removeChildrenMapKey(state, action: PayloadAction<string>) {
      if (state.children[action.payload]) {
        delete state.children[action.payload];
      }
    },

    // set block's relationship with its parent
    insertChild: (state, action: PayloadAction<{ id: string; childId: string; prevId: string | null }>) => {
      const { id, childId, prevId } = action.payload;
      const parent = state.nodes[id];
      const children = state.children[parent.children];
      const index = prevId ? children.indexOf(prevId) + 1 : 0;
      children.splice(index, 0, childId);
    },

    // remove block's relationship with its parent
    deleteChild: (state, action: PayloadAction<{ id: string; childId: string }>) => {
      const { id, childId } = action.payload;
      const parent = state.nodes[id];
      const children = state.children[parent.children];
      const index = children.indexOf(childId);
      children.splice(index, 1);
    },

    // move block to another parent
    moveNode: (state, action: PayloadAction<{ id: string; newParentId: string; newPrevId: string | null }>) => {
      const { id, newParentId, newPrevId } = action.payload;
      const newParent = state.nodes[newParentId];
      const oldParentId = state.nodes[id].parent;
      if (!oldParentId) return;
      const oldParent = state.nodes[oldParentId];

      state.nodes[id] = {
        ...state.nodes[id],
        parent: newParentId,
      };
      const index = state.children[oldParent.children].indexOf(id);
      state.children[oldParent.children].splice(index, 1);

      const newIndex = newPrevId ? state.children[newParent.children].indexOf(newPrevId) + 1 : 0;
      state.children[newParent.children].splice(newIndex, 0, id);
    },
  },
});

export const documentActions = documentSlice.actions;

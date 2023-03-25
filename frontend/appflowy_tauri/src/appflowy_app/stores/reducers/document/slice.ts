import { BlockType, TextDelta } from "@/appflowy_app/interfaces/document";
import { PayloadAction, createSlice } from "@reduxjs/toolkit";

export interface Node {
  id: string;
  parent: string | null;
  type: BlockType;
  selected?: boolean;
  delta: TextDelta[];
  data: {
    text?: string;
  };
}

export type NodeState = {
  nodes: Record<string, Node>;
  children: Record<string, string[]>;
};
const initialState: NodeState = {
  nodes: {},
  children: {},
};

export const documentSlice = createSlice({
  name: 'document',
  initialState: initialState,
  reducers: {
    clear: (state, action: PayloadAction) => {
      return initialState;
    },
    addNode: (state, action: PayloadAction<Node>) => {
      state.nodes[action.payload.id] = action.payload;
    },
    addChild: (state, action: PayloadAction<{ parentId: string, childId: string }>) => {
      const children = state.children[action.payload.parentId];
      if (children) {
        children.push(action.payload.childId);
      } else {
        state.children[action.payload.parentId] = [action.payload.childId]
      }
    },

    updateNode: (state, action: PayloadAction<{id: string; parent?: string; type?: BlockType; data?: any }>) => {
      state.nodes[action.payload.id] = {
        ...state.nodes[action.payload.id],
        ...action.payload
      }
    },

    removeNode: (state, action: PayloadAction<string>) => {
      const parentId = state.nodes[action.payload].parent;
      delete state.nodes[action.payload];
      if (parentId) {
        const index = state.children[parentId].indexOf(action.payload);
        if (index > -1) {
          state.children[parentId].splice(index, 1);
        }
      }
    },
  },
});

export const documentActions = documentSlice.actions;

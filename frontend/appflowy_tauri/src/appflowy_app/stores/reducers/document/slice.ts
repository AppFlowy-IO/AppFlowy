import { DocumentState, Node, TextSelection } from '@/appflowy_app/interfaces/document';
import { BlockEventPayloadPB } from '@/services/backend';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { parseValue, matchChange } from '$app/utils/document/subscribe';
import { getNextNodeId, getPrevNodeId } from '$app/utils/document/blocks/common';

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
      const selections = action.payload;
      const selected: Record<string, boolean> = {};
      selections.forEach((id) => {
        const node = state.nodes[id];
        if (!node.parent) {
          return;
        }
        selected[id] = selected[id] === undefined ? true : selected[id];
        selected[node.parent] = false;
        const nextNodeId = getNextNodeId(state, node.parent);
        const prevNodeId = getPrevNodeId(state, node.parent);
        if ((nextNodeId && selections.includes(nextNodeId)) || (prevNodeId && selections.includes(prevNodeId))) {
          selected[node.parent] = true;
        }
      });

      state.selections = selections.filter((id) => selected[id]);
    },

    // set block selected
    setSelectionById: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      state.selections = [id];
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
      const oldSelection = state.textSelections[blockId];
      if (JSON.stringify(oldSelection) === JSON.stringify(selection)) return;
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

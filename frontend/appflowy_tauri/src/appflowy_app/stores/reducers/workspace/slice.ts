import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface WorkspaceItem {
  id: string;
  name: string;
}

interface WorkspaceState {
  workspaces: WorkspaceItem[];
  currentWorkspace: WorkspaceItem | null;
}

const initialState: WorkspaceState = {
  workspaces: [],
  currentWorkspace: null,
};

export const workspaceSlice = createSlice({
  name: 'workspace',
  initialState,
  reducers: {
    initWorkspaces: (
      state,
      action: PayloadAction<{
        workspaces: WorkspaceItem[];
        currentWorkspace: WorkspaceItem | null;
      }>
    ) => {
      return action.payload;
    },

    onWorkspacesChanged: (
      state,
      action: PayloadAction<{
        workspaces: WorkspaceItem[];
        currentWorkspace: WorkspaceItem | null;
      }>
    ) => {
      return action.payload;
    },

    onWorkspaceChanged: (state, action: PayloadAction<WorkspaceItem>) => {
      const { id } = action.payload;
      const index = state.workspaces.findIndex((workspace) => workspace.id === id);

      if (index !== -1) {
        state.workspaces[index] = action.payload;
      }
    },

    onWorkspaceDeleted: (state, action: PayloadAction<string>) => {
      const id = action.payload;
      const index = state.workspaces.findIndex((workspace) => workspace.id === id);

      if (index !== -1) {
        state.workspaces.splice(index, 1);
      }
    },
  },
});

export const workspaceActions = workspaceSlice.actions;

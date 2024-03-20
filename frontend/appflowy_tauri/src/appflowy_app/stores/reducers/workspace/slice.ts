import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface WorkspaceItem {
  id: string;
  name: string;
  icon?: string;
}

interface WorkspaceState {
  workspaces: WorkspaceItem[];
  currentWorkspaceId: string | null;
}

const initialState: WorkspaceState = {
  workspaces: [],
  currentWorkspaceId: null,
};

export const workspaceSlice = createSlice({
  name: 'workspace',
  initialState,
  reducers: {
    initWorkspaces: (
      state,
      action: PayloadAction<{
        workspaces: WorkspaceItem[];
        currentWorkspaceId: string | null;
      }>
    ) => {
      return action.payload;
    },

    updateWorkspace: (state, action: PayloadAction<Partial<WorkspaceItem>>) => {
      const index = state.workspaces.findIndex((workspace) => workspace.id === action.payload.id);

      if (index !== -1) {
        state.workspaces[index] = {
          ...state.workspaces[index],
          ...action.payload,
        };
      }
    },
  },
});

export const workspaceActions = workspaceSlice.actions;

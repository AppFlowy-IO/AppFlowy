import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface IWorkspace {
  id?: string;
  name?: string;
}

export const workspaceSlice = createSlice({
  name: 'workspace',
  initialState: {} as IWorkspace,
  reducers: {
    updateWorkspace: (state, action: PayloadAction<IWorkspace>) => {
      return action.payload;
    },
  },
});

export const workspaceActions = workspaceSlice.actions;

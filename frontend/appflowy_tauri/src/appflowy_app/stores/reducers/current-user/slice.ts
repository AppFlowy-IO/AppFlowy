import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { nanoid } from 'nanoid';
import { WorkspaceSettingPB } from '../../../../services/backend/models/flowy-folder/workspace';

export interface ICurrentUser {
  id?: string;
  displayName?: string;
  email?: string;
  token?: string;
  isAuthenticated: boolean;
  workspaceSetting?: WorkspaceSettingPB;
}

const initialState: ICurrentUser | null = {
  id: nanoid(8),
  displayName: 'Me 😃',
  email: `${nanoid(4)}@gmail.com`,
  token: nanoid(8),
  isAuthenticated: false,
};

export const currentUserSlice = createSlice({
  name: 'currentUser',
  initialState: initialState,
  reducers: {
    updateUser: (state, action: PayloadAction<ICurrentUser>) => {
      return action.payload;
    },
    logout: () => {
      return {
        isAuthenticated: false,
      };
    },
  },
});

export const currentUserActions = currentUserSlice.actions;

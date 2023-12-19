import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { WorkspaceSettingPB } from '@/services/backend/models/flowy-folder2/workspace';
import { ThemeModePB as ThemeMode } from '@/services/backend';

export { ThemeMode };

export interface UserSetting {
  theme?: Theme;
  themeMode?: ThemeMode;
  language?: string;
}

export enum Theme {
  Default = 'default',
  Dandelion = 'dandelion',
  Lavender = 'lavender',
}

export interface ICurrentUser {
  id?: number;
  displayName?: string;
  email?: string;
  token?: string;
  isAuthenticated: boolean;
  workspaceSetting?: WorkspaceSettingPB;
  userSetting: UserSetting;
}

const initialState: ICurrentUser | null = {
  isAuthenticated: false,
  userSetting: {},
};

export const currentUserSlice = createSlice({
  name: 'currentUser',
  initialState: initialState,
  reducers: {
    checkUser: (state, action: PayloadAction<Partial<ICurrentUser>>) => {
      return {
        ...state,
        ...action.payload,
      };
    },
    updateUser: (state, action: PayloadAction<Partial<ICurrentUser>>) => {
      return {
        ...state,
        ...action.payload,
      };
    },
    logout: () => {
      return initialState;
    },
    setUserSetting: (state, action: PayloadAction<Partial<UserSetting>>) => {
      state.userSetting = {
        ...state.userSetting,
        ...action.payload,
      };
    },
  },
});

export const currentUserActions = currentUserSlice.actions;

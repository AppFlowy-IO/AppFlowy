import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { WorkspaceSettingPB } from '@/services/backend/models/flowy-folder/workspace';
import { ThemeModePB as ThemeMode } from '@/services/backend';

export { ThemeMode };

export interface UserSetting {
  theme?: Theme;
  themeMode?: ThemeMode;
  language?: string;
  isDark?: boolean;
}

export enum Theme {
  Default = 'default',
  Dandelion = 'dandelion',
  Lavender = 'lavender',
}

export enum LoginState {
  Loading = 'loading',
  Success = 'success',
  Error = 'error',
}

export interface ICurrentUser {
  id?: number;
  deviceId?: string;
  displayName?: string;
  email?: string;
  token?: string;
  iconUrl?: string;
  isAuthenticated: boolean;
  workspaceSetting?: WorkspaceSettingPB;
  userSetting: UserSetting;
  isLocal: boolean;
  loginState?: LoginState;
}

const initialState: ICurrentUser | null = {
  isAuthenticated: false,
  userSetting: {},
  isLocal: true,
};

export const currentUserSlice = createSlice({
  name: 'currentUser',
  initialState: initialState,
  reducers: {
    updateUser: (state, action: PayloadAction<Partial<ICurrentUser>>) => {
      return {
        ...state,
        ...action.payload,
        loginState: LoginState.Success,
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

    setLoginState: (state, action: PayloadAction<LoginState>) => {
      state.loginState = action.payload;
    },

    resetLoginState: (state) => {
      state.loginState = undefined;
    },
  },
});

export const currentUserActions = currentUserSlice.actions;

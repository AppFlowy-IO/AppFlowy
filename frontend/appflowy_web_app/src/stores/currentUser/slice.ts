import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { UserProfile, UserSetting } from '@/application/user.type';

export enum LoginState {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCESS = 'success',
  ERROR = 'error',
}

export interface InitialState {
  user?: UserProfile;
  isAuthenticated: boolean;
  userSetting?: UserSetting;
  loginState?: LoginState;
}

const initialState: InitialState = {
  isAuthenticated: false,
};

export const currentUserSlice = createSlice({
  name: 'currentUser',
  initialState: initialState,
  reducers: {
    updateUser: (state, action: PayloadAction<UserProfile>) => {
      state.user = action.payload;
      state.isAuthenticated = true;
    },
    logout: (state) => {
      state.user = undefined;
      state.isAuthenticated = false;
    },
    setUserSetting: (state, action: PayloadAction<UserSetting>) => {
      state.userSetting = action.payload;
    },
    loginStart: (state) => {
      state.loginState = LoginState.LOADING;
    },
    loginSuccess: (state) => {
      state.loginState = LoginState.SUCCESS;
    },
    loginError: (state) => {
      state.loginState = LoginState.ERROR;
    },
    resetLoginState: (state) => {
      state.loginState = LoginState.IDLE;
    },

  },
});

export const currentUserActions = currentUserSlice.actions;

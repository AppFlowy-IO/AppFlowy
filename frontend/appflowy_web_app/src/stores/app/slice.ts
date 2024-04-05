import { AFServiceConfig } from '@/application/services/services.type';
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

const defaultConfig: AFServiceConfig = {
  cloudConfig: {
    baseURL: import.meta.env.DEV
      ? import.meta.env.AF_BASE_URL || 'https://test.appflowy.cloud'
      : 'https://beta.appflowy.cloud',
    gotrueURL: import.meta.env.DEV
      ? import.meta.env.AF_GOTRUE_URL || 'https://test.appflowy.cloud/gotrue'
      : 'https://beta.appflowy.cloud/gotrue',
    wsURL: import.meta.env.DEV
      ? import.meta.env.AF_WS_URL || 'wss://test.appflowy.cloud/ws/v1'
      : 'wss://beta.appflowy.cloud/ws/v1',
  },
};

export interface AppState {
  appConfig: AFServiceConfig;
}

const initialState: AppState = {
  appConfig: defaultConfig,
};

export const slice = createSlice({
  name: 'app',
  initialState,
  reducers: {
    setAppConfig: (state, action: PayloadAction<AFServiceConfig>) => {
      state.appConfig = action.payload;
    },
  },
});

export const { setAppConfig } = slice.actions;
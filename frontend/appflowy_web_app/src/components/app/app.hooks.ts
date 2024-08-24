import { AFService, AFServiceConfig } from '@/application/services/services.type';
import { User } from '@/application/types';
import { createContext, useContext } from 'react';

const baseURL = import.meta.env.AF_BASE_URL || 'https://test.appflowy.cloud';
const gotrueURL = import.meta.env.AF_GOTRUE_URL || 'https://test.appflowy.cloud/gotrue';
const wsURL = import.meta.env.AF_WS_URL || 'wss://test.appflowy.cloud/ws/v1';

export const defaultConfig: AFServiceConfig = {
  cloudConfig: {
    baseURL,
    gotrueURL,
    wsURL,
  },
};

export const AFConfigContext = createContext<
  | {
  service: AFService | undefined;
  isAuthenticated: boolean;
  currentUser?: User;
  openLoginModal: (redirectTo?: string) => void;
}
  | undefined
>(undefined);

export function useCurrentUser () {
  const context = useContext(AFConfigContext);

  if (!context) {
    throw new Error('useCurrentUser must be used within a AFConfigContext');
  }

  return context.currentUser;
}

export function useService () {
  const context = useContext(AFConfigContext);

  if (!context) {
    throw new Error('useService must be used within a AFConfigContext');
  }

  return context.service;
}
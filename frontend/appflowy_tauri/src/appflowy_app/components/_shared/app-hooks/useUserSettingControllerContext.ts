import { UserSettingController } from '$app/stores/effects/user/user_setting_controller';
import { createContext, useContext } from 'react';

export const UserSettingControllerContext = createContext<UserSettingController | undefined>(undefined);
export function useUserSettingControllerContext() {
  const context = useContext(UserSettingControllerContext);

  return context;
}

import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useCallback, useEffect, useMemo } from 'react';
import { UserSettingController } from '$app/stores/effects/user/user_setting_controller';
import { currentUserActions } from '$app_reducers/current-user/slice';
import { Theme as ThemeType, ThemeMode } from '$app/interfaces';
import { createTheme } from '@mui/material/styles';
import { getDesignTokens } from '$app/utils/mui';
import { useTranslation } from 'react-i18next';

export function useUserSetting() {
  const dispatch = useAppDispatch();
  const { i18n } = useTranslation();
  const currentUser = useAppSelector((state) => state.currentUser);
  const userSettingController = useMemo(() => {
    if (!currentUser?.id) return;
    const controller = new UserSettingController(currentUser.id);

    return controller;
  }, [currentUser?.id]);

  const loadUserSetting = useCallback(async () => {
    if (!userSettingController) return;
    const settings = await userSettingController.getAppearanceSetting();

    if (!settings) return;
    dispatch(currentUserActions.setUserSetting(settings));
    await i18n.changeLanguage(settings.language);
  }, [dispatch, i18n, userSettingController]);

  useEffect(() => {
    void loadUserSetting();
  }, [loadUserSetting]);

  const { themeMode = ThemeMode.Light, theme: themeType = ThemeType.Default } = useAppSelector((state) => {
    return state.currentUser.userSetting || {};
  });

  const muiTheme = useMemo(() => createTheme(getDesignTokens(themeMode)), [themeMode]);

  return {
    muiTheme,
    themeMode,
    themeType,
    userSettingController,
  };
}

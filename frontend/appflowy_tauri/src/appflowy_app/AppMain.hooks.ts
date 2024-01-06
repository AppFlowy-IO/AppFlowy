import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useCallback, useEffect, useMemo } from 'react';
import { UserSettingController } from '$app/stores/effects/user/user_setting_controller';
import { currentUserActions } from '$app_reducers/current-user/slice';
import { Theme as ThemeType, ThemeMode } from '$app/stores/reducers/current-user/slice';
import { createTheme } from '@mui/material/styles';
import { getDesignTokens } from '$app/utils/mui';
import { useTranslation } from 'react-i18next';
import { ThemeModePB } from '@/services/backend';

export function useUserSetting() {
  const dispatch = useAppDispatch();
  const { i18n } = useTranslation();

  const currentUser = useAppSelector((state) => state.currentUser);
  const userSettingController = useMemo(() => {
    if (!currentUser?.id) return;

    return new UserSettingController(currentUser.id);
  }, [currentUser?.id]);

  const handleSystemThemeChange = useCallback(() => {
    const mode = window.matchMedia('(prefers-color-scheme: dark)').matches ? ThemeMode.Dark : ThemeMode.Light;

    dispatch(currentUserActions.setUserSetting({ themeMode: mode }));
  }, [dispatch]);

  const loadUserSetting = useCallback(async () => {
    if (!userSettingController) return;
    const settings = await userSettingController.getAppearanceSetting();

    if (!settings) return;
    dispatch(currentUserActions.setUserSetting(settings));

    if (settings.themeMode === ThemeModePB.System) {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

      handleSystemThemeChange();

      mediaQuery.addEventListener('change', handleSystemThemeChange);
    }

    await i18n.changeLanguage(settings.language);
  }, [dispatch, handleSystemThemeChange, i18n, userSettingController]);

  useEffect(() => {
    void loadUserSetting();
  }, [loadUserSetting]);

  const { themeMode = ThemeMode.Light, theme: themeType = ThemeType.Default } = useAppSelector((state) => {
    return state.currentUser.userSetting || {};
  });

  useEffect(() => {
    const html = document.documentElement;

    html?.setAttribute('data-dark-mode', String(themeMode === ThemeMode.Dark));
    html?.setAttribute('data-theme', themeType);
  }, [themeType, themeMode]);

  useEffect(() => {
    return () => {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

      mediaQuery.removeEventListener('change', handleSystemThemeChange);
    };
  }, [dispatch, handleSystemThemeChange]);

  const muiTheme = useMemo(() => createTheme(getDesignTokens(themeMode)), [themeMode]);

  return {
    muiTheme,
    themeMode,
    themeType,
    userSettingController,
  };
}

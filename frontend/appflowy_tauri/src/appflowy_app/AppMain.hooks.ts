import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useEffect, useMemo } from 'react';
import { currentUserActions } from '$app_reducers/current-user/slice';
import { Theme as ThemeType, ThemeMode } from '$app/stores/reducers/current-user/slice';
import { createTheme } from '@mui/material/styles';
import { getDesignTokens } from '$app/utils/mui';
import { useTranslation } from 'react-i18next';
import { UserService } from '$app/application/user/user.service';

export function useUserSetting() {
  const dispatch = useAppDispatch();
  const { i18n } = useTranslation();
  const {
    themeMode = ThemeMode.System,
    isDark = false,
    theme: themeType = ThemeType.Default,
  } = useAppSelector((state) => {
    return state.currentUser.userSetting || {};
  });

  useEffect(() => {
    void (async () => {
      const settings = await UserService.getAppearanceSetting();

      if (!settings) return;
      dispatch(currentUserActions.setUserSetting(settings));
      await i18n.changeLanguage(settings.language);
    })();
  }, [dispatch, i18n]);

  useEffect(() => {
    const html = document.documentElement;

    html?.setAttribute('data-dark-mode', String(isDark));
  }, [isDark]);

  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

    const handleSystemThemeChange = () => {
      if (themeMode !== ThemeMode.System) return;
      dispatch(
        currentUserActions.setUserSetting({
          isDark: mediaQuery.matches,
        })
      );
    };

    mediaQuery.addEventListener('change', handleSystemThemeChange);

    return () => {
      mediaQuery.removeEventListener('change', handleSystemThemeChange);
    };
  }, [dispatch, themeMode]);

  const muiTheme = useMemo(() => createTheme(getDesignTokens(isDark)), [isDark]);

  return {
    muiTheme,
    themeMode,
    themeType,
  };
}

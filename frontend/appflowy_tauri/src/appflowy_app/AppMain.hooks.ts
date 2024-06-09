import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useEffect, useMemo } from 'react';
import { currentUserActions, LoginState } from '$app_reducers/current-user/slice';
import { Theme as ThemeType, ThemeMode } from '$app/stores/reducers/current-user/slice';
import { createTheme } from '@mui/material/styles';
import { getDesignTokens } from '$app/utils/mui';
import { useTranslation } from 'react-i18next';
import { UserService } from '$app/application/user/user.service';

export function useUserSetting() {
  const dispatch = useAppDispatch();
  const { i18n } = useTranslation();
  const loginState = useAppSelector((state) => state.currentUser.loginState);

  const { themeMode = ThemeMode.System, theme: themeType = ThemeType.Default } = useAppSelector((state) => {
    return {
      themeMode: state.currentUser.userSetting.themeMode,
      theme: state.currentUser.userSetting.theme,
    };
  });

  const isDark =
    themeMode === ThemeMode.Dark ||
    (themeMode === ThemeMode.System && window.matchMedia('(prefers-color-scheme: dark)').matches);

  useEffect(() => {
    if (loginState !== LoginState.Success && loginState !== undefined) return;
    void (async () => {
      const settings = await UserService.getAppearanceSetting();

      if (!settings) return;
      dispatch(currentUserActions.setUserSetting(settings));
      await i18n.changeLanguage(settings.language);
    })();
  }, [dispatch, i18n, loginState]);

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

import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useEffect, useMemo } from 'react';
import { UserSettingController } from '$app/stores/effects/user/user_setting_controller';
import { currentUserActions } from '$app_reducers/current-user/slice';
import { Theme as ThemeType, Theme, ThemeMode } from '$app/interfaces';
import { createTheme } from '@mui/material/styles';
import { getDesignTokens } from '$app/utils/mui';

export function useUserSetting() {
  const dispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);
  const userSettingController = useMemo(() => {
    if (!currentUser?.id) return;
    const controller = new UserSettingController(currentUser.id);

    return controller;
  }, [currentUser?.id]);

  useEffect(() => {
    userSettingController?.getAppearanceSetting().then((res) => {
      if (!res) return;
      const locale = res.locale;
      let language = 'en';

      if (locale.language_code && locale.country_code) {
        language = `${locale.language_code}-${locale.country_code}`;
      } else if (locale.language_code) {
        language = locale.language_code;
      }

      dispatch(
        currentUserActions.setUserSetting({
          themeMode: res.theme_mode,
          theme: res.theme as Theme,
          language: language,
        })
      );
    });
  }, [dispatch, userSettingController]);

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

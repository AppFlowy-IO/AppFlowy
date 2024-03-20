import { useCallback } from 'react';
import { createHotkey, HOT_KEY_NAME } from '$app/utils/hotkeys';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { currentUserActions, ThemeMode } from '$app_reducers/current-user/slice';
import { UserService } from '$app/application/user/user.service';
import { sidebarActions } from '$app_reducers/sidebar/slice';

export function useShortcuts() {
  const dispatch = useAppDispatch();
  const userSettingState = useAppSelector((state) => state.currentUser.userSetting);
  const { isDark } = userSettingState;

  const switchThemeMode = useCallback(() => {
    const newSetting = {
      themeMode: isDark ? ThemeMode.Light : ThemeMode.Dark,
      isDark: !isDark,
    };

    dispatch(currentUserActions.setUserSetting(newSetting));
    void UserService.setAppearanceSetting({
      theme_mode: newSetting.themeMode,
    });
  }, [dispatch, isDark]);

  const toggleSidebar = useCallback(() => {
    dispatch(sidebarActions.toggleCollapse());
  }, [dispatch]);

  return useCallback(
    (e: KeyboardEvent) => {
      switch (true) {
        /**
         * Toggle theme: Mod+L
         * Switch between light and dark theme
         */
        case createHotkey(HOT_KEY_NAME.TOGGLE_THEME)(e):
          switchThemeMode();
          break;
        /**
         * Toggle sidebar: Mod+. (period)
         * Prevent the default behavior of the browser (Exit full screen)
         * Collapse or expand the sidebar
         */
        case createHotkey(HOT_KEY_NAME.TOGGLE_SIDEBAR)(e):
          e.preventDefault();
          toggleSidebar();
          break;
        default:
          break;
      }
    },
    [toggleSidebar, switchThemeMode]
  );
}

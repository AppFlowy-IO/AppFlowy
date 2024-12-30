import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { useEffect, useState, createContext, useCallback } from 'react';

export const ThemeModeContext = createContext<
  | {
  isDark: boolean;
  setDark: (isDark: boolean) => void;
}
  | undefined
>(undefined);

export function useAppThemeMode () {
  const fixedTheme = window.location.search.includes('theme') ? new URLSearchParams(window.location.search).get('theme') : null;
  const [isDark, setIsDark] = useState<boolean>(() => {
    if (fixedTheme === 'light') {
      return false;
    }

    if (fixedTheme === 'dark') {
      return true;
    }

    const darkMode = localStorage.getItem('dark-mode');

    return darkMode === 'true';
  });

  const onKeyDown = useCallback((e: KeyboardEvent) => {
    switch (true) {
      case createHotkey(HOT_KEY_NAME.TOGGLE_THEME)(e):
        e.preventDefault();
        setIsDark(prev => !prev);
        break;
      default:
        break;
    }
  }, []);

  useEffect(() => {
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [onKeyDown]);

  useEffect(() => {
    if (fixedTheme) return;

    function detectColorScheme () {
      const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

      setIsDark(darkModeMediaQuery.matches);
    }

    if (localStorage.getItem('dark-mode') === null) {
      detectColorScheme();
    }

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', detectColorScheme);
    return () => {
      window.matchMedia('(prefers-color-scheme: dark)').removeEventListener('change', detectColorScheme);
    };
  }, [fixedTheme]);

  useEffect(() => {
    document.documentElement.setAttribute('data-dark-mode', isDark ? 'true' : 'false');
    localStorage.setItem('dark-mode', isDark ? 'true' : 'false');
  }, [isDark]);

  return {
    isDark,
    setIsDark,
  };
}

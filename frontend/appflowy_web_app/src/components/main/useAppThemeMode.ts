import { useEffect, useState, createContext } from 'react';

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

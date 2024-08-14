import { useEffect, useState, createContext } from 'react';
import { useSearchParams } from 'react-router-dom';

export const ThemeModeContext = createContext<
  | {
  isDark: boolean;
  setDark: (isDark: boolean) => void;
}
  | undefined
>(undefined);

export function useAppThemeMode () {
  const [search] = useSearchParams();
  const fixedTheme = search.get('theme') === 'light' || search.get('theme') === 'dark';
  const [isDark, setIsDark] = useState<boolean>(() => {
    const darkMode = localStorage.getItem('dark-mode');

    return darkMode === 'true';
  });

  useEffect(() => {
    if (search.get('theme') === 'light') {
      setIsDark(false);
    }

    if (search.get('theme') === 'dark') {
      setIsDark(true);
    }
  }, [search]);

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

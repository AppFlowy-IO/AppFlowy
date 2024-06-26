import { useEffect, useState, createContext } from 'react';

export const ThemeModeContext = createContext<
  | {
      isDark: boolean;
      setDark: (isDark: boolean) => void;
    }
  | undefined
>(undefined);

export function useAppThemeMode() {
  const [isDark, setIsDark] = useState<boolean>(false);

  useEffect(() => {
    function detectColorScheme() {
      const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

      setIsDark(darkModeMediaQuery.matches);
    }

    detectColorScheme();

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', detectColorScheme);
    return () => {
      window.matchMedia('(prefers-color-scheme: dark)').removeEventListener('change', detectColorScheme);
    };
  }, []);

  useEffect(() => {
    console.log('isDark', isDark);
    document.documentElement.setAttribute('data-dark-mode', isDark ? 'true' : 'false');
  }, [isDark]);

  return {
    isDark,
    setIsDark,
  };
}

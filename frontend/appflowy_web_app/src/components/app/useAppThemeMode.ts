import { useEffect, useState } from 'react';

export function useAppThemeMode() {
  const [isDark, setIsDark] = useState<boolean>(false);

  useEffect(() => {
    function detectColorScheme() {
      const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

      setIsDark(darkModeMediaQuery.matches);
      document.documentElement.setAttribute('data-dark-mode', darkModeMediaQuery.matches ? 'true' : 'false');
    }

    detectColorScheme();

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', detectColorScheme);
    return () => {
      window.matchMedia('(prefers-color-scheme: dark)').removeEventListener('change', detectColorScheme);
    };
  }, []);

  return {
    isDark,
  };
}

import { ThemeMode } from '$app/interfaces';
import { ThemeOptions } from '@mui/material';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
export const getDesignTokens = (mode: ThemeMode): ThemeOptions => {
  const isDark = mode === ThemeMode.Dark;

  return {
    typography: {
      fontFamily: ['Poppins'].join(','),
      fontSize: 12,
      button: {
        textTransform: 'none',
      },
    },
    palette: {
      mode: isDark ? 'dark' : 'light',
      primary: {
        main: '#00BCF0',
        dark: '#00BCF0',
      },
      error: {
        main: '#FB006D',
        dark: '#D32772',
      },
      warning: {
        main: '#FFC107',
        dark: '#E9B320',
      },
      info: {
        main: '#00BCF0',
        dark: '#2E9DBB',
      },
      success: {
        main: '#66CF80',
        dark: '#3BA856',
      },
      text: {
        primary: isDark ? '#E2E9F2' : '#333333',
        secondary: isDark ? '#7B8A9D' : '#828282',
        disabled: isDark ? '#363D49' : '#F2F2F2',
      },
      divider: isDark ? '#59647A' : '#BDBDBD',
      background: {
        default: isDark ? '#1A202C' : '#FFFFFF',
        paper: isDark ? '#1A202C' : '#FFFFFF',
      },
    },
  };
};

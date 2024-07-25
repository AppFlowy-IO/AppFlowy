import { ThemeModeContext, useAppThemeMode } from '@/components/app/useAppThemeMode';
import React, { useMemo } from 'react';
import createTheme from '@mui/material/styles/createTheme';
import ThemeProvider from '@mui/material/styles/ThemeProvider';
import '@/i18n/config';

import 'src/styles/tailwind.css';
import 'src/styles/template.css';

function AppTheme({ children }: { children: React.ReactNode }) {
  const { isDark, setIsDark } = useAppThemeMode();

  const theme = useMemo(
    () =>
      createTheme({
        typography: {
          fontFamily: ['inherit'].join(','),
          fontSize: 14,
          button: {
            textTransform: 'none',
          },
        },
        components: {
          MuiMenuItem: {
            defaultProps: {
              sx: {
                '&.Mui-selected.Mui-focusVisible': {
                  backgroundColor: 'var(--fill-list-hover)',
                },
                '&.Mui-focusVisible': {
                  backgroundColor: 'unset',
                },
              },
            },
          },
          MuiIconButton: {
            styleOverrides: {
              root: {
                '&:hover': {
                  backgroundColor: 'var(--fill-list-hover)',
                },
                borderRadius: '4px',
                padding: '2px',
                '&.MuiIconButton-colorInherit': {
                  color: 'var(--icon-primary)',
                },
              },
            },
          },
          MuiButton: {
            styleOverrides: {
              text: {
                borderRadius: '8px',
                '&:hover': {
                  backgroundColor: 'var(--fill-list-hover)',
                },
              },
              contained: {
                color: 'var(--content-on-fill)',
                boxShadow: 'none',
                '&:hover': {
                  backgroundColor: 'var(--content-blue-600)',
                },
                borderRadius: '8px',
                '&.Mui-disabled': {
                  backgroundColor: 'var(--content-blue-400)',
                  opacity: 0.3,
                  color: 'var(--content-on-fill)',
                },
              },
              outlined: {
                '&.MuiButton-outlinedInherit': {
                  borderColor: 'var(--line-divider)',
                },
                borderRadius: '8px',
              },
            },
          },

          MuiButtonBase: {
            styleOverrides: {
              root: {
                '&:not(.MuiButton-contained)': {
                  '&:hover': {
                    backgroundColor: 'var(--fill-list-hover)',
                  },
                  '&:active': {
                    backgroundColor: 'var(--fill-list-hover)',
                  },
                },

                borderRadius: '4px',
                padding: '2px',
                boxShadow: 'none !important',
              },
            },
          },
          MuiPaper: {
            styleOverrides: {
              root: {
                backgroundImage: 'none',
                boxShadow: 'var(--shadow)',
                borderRadius: '10px',
              },
            },
          },
          MuiDialog: {
            styleOverrides: {
              paper: {
                borderRadius: '12px',
              },
            },
            defaultProps: {
              sx: {
                '& .MuiBackdrop-root': {
                  backgroundColor: 'var(--bg-mask)',
                },
              },
            },
          },

          MuiTooltip: {
            styleOverrides: {
              arrow: {
                color: 'var(--bg-tips)',
              },
              tooltip: {
                backgroundColor: 'var(--bg-tips)',
                color: 'var(--text-title)',
                fontSize: '0.85rem',
                borderRadius: '8px',
                fontWeight: 400,
              },
            },
          },
          MuiInputBase: {
            defaultProps: {
              sx: {
                '&.Mui-disabled, .Mui-disabled': {
                  color: 'var(--text-caption)',
                  WebkitTextFillColor: 'var(--text-caption) !important',
                },
              },
            },
            styleOverrides: {
              input: {
                backgroundColor: 'transparent !important',
              },
            },
          },
          MuiDivider: {
            styleOverrides: {
              root: {
                borderColor: 'var(--line-divider)',
              },
            },
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
      }),
    [isDark]
  );

  return (
    <ThemeModeContext.Provider
      value={{
        isDark,
        setDark: setIsDark,
      }}
    >
      <ThemeProvider theme={theme}>{children}</ThemeProvider>
    </ThemeModeContext.Provider>
  );
}

export default AppTheme;

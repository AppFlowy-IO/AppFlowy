import React, { useCallback, useEffect, useMemo } from 'react';
import Select from '@mui/material/Select';
import { Theme, ThemeMode, UserSetting } from '$app/interfaces';
import MenuItem from '@mui/material/MenuItem';

function AppearanceSetting({
  theme = Theme.Default,
  themeMode = ThemeMode.Light,
  onChange,
}: {
  theme?: Theme;
  themeMode?: ThemeMode;
  onChange: (setting: UserSetting) => void;
}) {
  useEffect(() => {
    const html = document.documentElement;

    html?.setAttribute('data-dark-mode', String(themeMode === ThemeMode.Dark));
    html?.setAttribute('data-theme', theme);
  }, [theme, themeMode]);

  const themeModeOptions = useMemo(
    () => [
      {
        value: ThemeMode.Light,
        content: 'Light',
      },
      {
        value: ThemeMode.Dark,
        content: 'Dark',
      },
    ],
    []
  );

  const themeOptions = useMemo(
    () => [
      {
        value: Theme.Default,
        content: 'Default',
      },
      {
        value: Theme.Dandelion,
        content: 'Dandelion',
      },
      {
        value: Theme.Lavender,
        content: 'Lavender',
      },
    ],
    []
  );

  const renderSelect = useCallback(
    (
      items: {
        options: { value: ThemeMode | Theme; content: string }[];
        label: string;
        value: ThemeMode | Theme;
        onChange: (newValue: ThemeMode | Theme) => void;
      }[]
    ) => {
      return items.map((item) => {
        const { value, options, label, onChange } = item;

        return (
          <div key={value} className={'mb-2 flex items-center justify-between text-sm'}>
            <div className={'flex-1 text-text-title'}>{label}</div>
            <div className={'flex items-center'}>
              <Select
                sx={{
                  fontSize: '0.85rem',
                }}
                variant={'standard'}
                value={value}
                onChange={(e) => {
                  onChange(e.target.value as ThemeMode | Theme);
                }}
              >
                {options.map((option) => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.content}
                  </MenuItem>
                ))}
              </Select>
            </div>
          </div>
        );
      });
    },
    []
  );

  return (
    <div className={'flex flex-col'}>
      {renderSelect([
        {
          options: themeModeOptions,
          label: 'Theme Mode',
          value: themeMode,
          onChange: (newValue) => {
            onChange({
              themeMode: newValue as ThemeMode,
            });
          },
        },
        {
          options: themeOptions,
          label: 'Theme',
          value: theme,
          onChange: (newValue) => {
            onChange({
              theme: newValue as Theme,
            });
          },
        },
      ])}
    </div>
  );
}

export default AppearanceSetting;

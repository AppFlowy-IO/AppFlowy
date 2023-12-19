import React, { useCallback, useEffect, useMemo } from 'react';
import Select from '@mui/material/Select';
import { Theme, ThemeMode, UserSetting } from '$app/stores/reducers/current-user/slice';
import MenuItem from '@mui/material/MenuItem';
import { useTranslation } from 'react-i18next';

function AppearanceSetting({
  theme = Theme.Default,
  themeMode = ThemeMode.Light,
  onChange,
}: {
  theme?: Theme;
  themeMode?: ThemeMode;
  onChange: (setting: UserSetting) => void;
}) {
  const { t } = useTranslation();

  useEffect(() => {
    const html = document.documentElement;

    html?.setAttribute('data-dark-mode', String(themeMode === ThemeMode.Dark));
    html?.setAttribute('data-theme', theme);
  }, [theme, themeMode]);

  const themeModeOptions = useMemo(
    () => [
      {
        value: ThemeMode.Light,
        content: t('settings.appearance.themeMode.light'),
      },
      {
        value: ThemeMode.Dark,
        content: t('settings.appearance.themeMode.dark'),
      },
    ],
    [t]
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
          label: t('settings.appearance.themeMode.label'),
          value: themeMode,
          onChange: (newValue) => {
            onChange({
              themeMode: newValue as ThemeMode,
            });
          },
        },
        {
          options: themeOptions,
          label: t('settings.appearance.theme'),
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

import React, { useCallback, useMemo } from 'react';
import Select from '@mui/material/Select';
import { Theme, ThemeMode, UserSetting } from '$app/stores/reducers/current-user/slice';
import MenuItem from '@mui/material/MenuItem';
import { useTranslation } from 'react-i18next';

function AppearanceSetting({
  themeMode = ThemeMode.System,
  onChange,
}: {
  theme?: Theme;
  themeMode?: ThemeMode;
  onChange: (setting: UserSetting) => void;
}) {
  const { t } = useTranslation();

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
      {
        value: ThemeMode.System,
        content: t('settings.appearance.themeMode.system'),
      },
    ],
    [t]
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
                  <MenuItem key={option.value} className={'my-1 rounded-none px-2 py-1 text-xs'} value={option.value}>
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
              isDark:
                newValue === ThemeMode.Dark ||
                (newValue === ThemeMode.System && window.matchMedia('(prefers-color-scheme: dark)').matches),
            });
          },
        },
      ])}
    </div>
  );
}

export default AppearanceSetting;

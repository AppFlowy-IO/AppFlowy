import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';
import React, { useCallback } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { currentUserActions } from '$app_reducers/current-user/slice';
import { UserService } from '$app/application/user/user.service';

const languages = [
  {
    key: 'ar-SA',
    title: 'العربية',
  },
  { key: 'ca-ES', title: 'Català' },
  { key: 'de-DE', title: 'Deutsch' },
  { key: 'en', title: 'English' },
  { key: 'es-VE', title: 'Español (Venezuela)' },
  { key: 'eu-ES', title: 'Español' },
  { key: 'fr-FR', title: 'Français' },
  { key: 'hu-HU', title: 'Magyar' },
  { key: 'id-ID', title: 'Bahasa Indonesia' },
  { key: 'it-IT', title: 'Italiano' },
  { key: 'ja-JP', title: '日本語' },
  { key: 'ko-KR', title: '한국어' },
  { key: 'pl-PL', title: 'Polski' },
  { key: 'pt-BR', title: 'Português' },
  { key: 'pt-PT', title: 'Português' },
  { key: 'ru-RU', title: 'Русский' },
  { key: 'sv', title: 'Svenska' },
  { key: 'th-TH', title: 'ไทย' },
  { key: 'tr-TR', title: 'Türkçe' },
  { key: 'zh-CN', title: '简体中文' },
  { key: 'zh-TW', title: '繁體中文' },
];

export const LanguageSetting = () => {
  const { t, i18n } = useTranslation();
  const userSettingState = useAppSelector((state) => state.currentUser.userSetting);
  const dispatch = useAppDispatch();
  const selectedLanguage = userSettingState.language;

  const [hoverKey, setHoverKey] = React.useState<string | null>(null);

  const handleChange = useCallback(
    (language: string) => {
      const newSetting = { ...userSettingState, language };

      dispatch(currentUserActions.setUserSetting(newSetting));
      const newLanguage = newSetting.language || 'en';

      void UserService.setAppearanceSetting({
        theme: newSetting.theme,
        theme_mode: newSetting.themeMode,
        locale: {
          language_code: newLanguage.split('-')[0],
          country_code: newLanguage.split('-')[1],
        },
      });
    },
    [dispatch, userSettingState]
  );

  const handleKeyDown = useCallback((e: React.KeyboardEvent<HTMLDivElement>) => {
    if (e.key === 'Escape') {
      e.preventDefault();
    }
  }, []);

  return (
    <>
      <Typography className={'mb-2 font-normal'} variant={'subtitle1'}>
        {t('newSettings.workplace.appearance.language')}
      </Typography>

      <Select
        variant={'outlined'}
        size={'small'}
        className={'w-[180px] rounded-xl'}
        value={selectedLanguage}
        onOpen={() => {
          setHoverKey(selectedLanguage ?? null);
        }}
        onChange={(e) => {
          const language = e.target.value;

          handleChange(language);
          void i18n.changeLanguage(language);
        }}
        MenuProps={{
          onKeyDown: handleKeyDown,
        }}
      >
        {languages.map((option) => (
          <MenuItem
            onFocus={() => {
              setHoverKey(option.key);
            }}
            onMouseEnter={(e) => {
              e.currentTarget.focus();
            }}
            key={option.key}
            style={{
              backgroundColor: option.key === hoverKey ? 'var(--fill-list-active)' : undefined,
            }}
            className={'my-1 w-full rounded-none px-2 py-1 text-xs hover:bg-transparent'}
            value={option.key}
          >
            {option.title}
          </MenuItem>
        ))}
      </Select>
    </>
  );
};

import React from 'react';
import { useTranslation } from 'react-i18next';
import Select from '@mui/material/Select';
import { UserSetting } from '$app/stores/reducers/current-user/slice';
import MenuItem from '@mui/material/MenuItem';

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

function LanguageSetting({
  language = 'en',
  onChange,
}: {
  language?: string;
  onChange: (setting: UserSetting) => void;
}) {
  const { t, i18n } = useTranslation();

  return (
    <div className={'flex flex-col'}>
      <div className={'mb-2 flex items-center justify-between text-sm'}>
        <div className={'flex-1 text-text-title'}>{t('settings.menu.language')}</div>
        <div className={'flex items-center'}>
          <Select
            sx={{
              fontSize: '0.85rem',
            }}
            variant={'standard'}
            value={language}
            onChange={(e) => {
              const language = e.target.value;

              onChange({
                language,
              });
              void i18n.changeLanguage(language);
            }}
          >
            {languages.map((option) => (
              <MenuItem key={option.key} value={option.key}>
                {option.title}
              </MenuItem>
            ))}
          </Select>
        </div>
      </div>
    </div>
  );
}

export default LanguageSetting;

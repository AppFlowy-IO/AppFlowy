import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Select from '@mui/material/Select';
import { UserSetting } from '$app/interfaces';
import MenuItem from '@mui/material/MenuItem';

function LanguageSetting({
  language = 'en',
  onChange,
}: {
  language?: string;
  onChange: (setting: UserSetting) => void;
}) {
  const { t, i18n } = useTranslation();

  const options = useMemo(
    () => [
      {
        key: 'en',
        title: 'English',
      },
      { key: 'ca_ES', title: 'Català' },
      { key: 'de_DE', title: 'Deutsch' },
      { key: 'es_VE', title: 'Español (Venezuela)' },
      { key: 'eu_ES', title: 'Español' },
      { key: 'fr_CA', title: 'Français (Canada)' },
      { key: 'fr_FR', title: 'Français' },
      { key: 'hu_HU', title: 'Magyar' },
      { key: 'id_ID', title: 'Bahasa Indonesia' },
      { key: 'it_IT', title: 'Italiano' },
      { key: 'ja_JP', title: '日本語' },
      { key: 'ko_KR', title: '한국어' },
      { key: 'pl_PL', title: 'Polski' },
      { key: 'pt_BR', title: 'Português' },
      { key: 'pt_PT', title: 'Português' },
      { key: 'ru_RU', title: 'Русский' },
      { key: 'sv_SE', title: 'Svenska' },
      { key: 'tr_TR', title: 'Türkçe' },
      { key: 'zh_CN', title: '简体中文' },
      { key: 'zh_TW', title: '繁體中文' },
      { key: 'vi_VN', title: 'Tiếng Việt' },
      { key: 'th_TH', title: 'ภาษาไทย' },
      { key: 'nl_NL', title: 'Nederlands' },
    ],
    []
  );

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
              i18n.changeLanguage(language);
            }}
          >
            {options.map((option) => (
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

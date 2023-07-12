import React, { useMemo } from 'react';
import LanguageIcon from '@mui/icons-material/Language';
import PaletteOutlined from '@mui/icons-material/PaletteOutlined';
import { useTranslation } from 'react-i18next';

export enum MenuItem {
  Appearance = 'Appearance',
  Language = 'Language',
}

function UserSettingMenu({ selected, onSelect }: { onSelect: (selected: MenuItem) => void; selected: MenuItem }) {
  const { t } = useTranslation();

  const options = useMemo(() => {
    return [
      {
        label: t('settings.menu.appearance'),
        value: MenuItem.Appearance,
        icon: <PaletteOutlined />,
      },
      {
        label: t('settings.menu.language'),
        value: MenuItem.Language,
        icon: <LanguageIcon />,
      },
    ];
  }, [t]);

  return (
    <div className={'h-[300px] w-[200px] border-r border-solid border-r-line-border pr-4 text-sm'}>
      {options.map((option) => {
        return (
          <div
            key={option.value}
            onClick={() => {
              onSelect(option.value);
            }}
            className={`my-1 flex h-10 w-full cursor-pointer items-center justify-start rounded-md px-4 py-2 text-text-title ${
              selected === option.value ? 'bg-fill-list-hover' : 'hover:text-content-blue-300'
            }`}
          >
            <div className={'mr-2'}>{option.icon}</div>
            <div>{option.label}</div>
          </div>
        );
      })}
    </div>
  );
}

export default UserSettingMenu;

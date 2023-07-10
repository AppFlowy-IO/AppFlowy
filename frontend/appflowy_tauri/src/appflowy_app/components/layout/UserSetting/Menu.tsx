import React, { useMemo } from 'react';
import LanguageIcon from '@mui/icons-material/Language';
import PaletteOutlined from '@mui/icons-material/PaletteOutlined';

export enum MenuItem {
  Appearance = 'Appearance',
  Language = 'Language',
}

function UserSettingMenu({ selected, onSelect }: { onSelect: (selected: MenuItem) => void; selected: MenuItem }) {
  const options = useMemo(() => {
    return [
      {
        label: 'Appearance',
        value: MenuItem.Appearance,
        icon: <PaletteOutlined />,
      },
      {
        label: 'Language',
        value: MenuItem.Language,
        icon: <LanguageIcon />,
      },
    ];
  }, []);

  return (
    <div className={'h-[300px] w-[200px] border-r border-solid border-r-line-border pr-2 text-sm'}>
      {options.map((option) => {
        return (
          <div
            key={option.value}
            onClick={() => {
              onSelect(option.value);
            }}
            className={`my-1 flex h-10 w-full cursor-pointer items-center justify-start rounded-md px-4 py-2 text-text-title ${
              selected === option.value ? 'bg-fill-hover' : 'hover:bg-fill-hover'
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

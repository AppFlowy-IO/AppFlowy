import React, { useMemo } from 'react';
import { MenuItem } from './Menu';
import AppearanceSetting from './AppearanceSetting';
import LanguageSetting from './LanguageSetting';

import { UserSetting } from '$app/interfaces';

function UserSettingPanel({
  selected,
  userSettingState = {},
  onChange,
}: {
  selected: MenuItem;
  userSettingState?: UserSetting;
  onChange: (setting: Partial<UserSetting>) => void;
}) {
  const { theme, themeMode, language } = userSettingState;

  const options = useMemo(() => {
    return [
      {
        value: MenuItem.Appearance,
        content: <AppearanceSetting onChange={onChange} theme={theme} themeMode={themeMode} />,
      },
      {
        value: MenuItem.Language,
        content: <LanguageSetting onChange={onChange} language={language} />,
      },
    ];
  }, [language, onChange, theme, themeMode]);

  const option = options.find((option) => option.value === selected);

  return <div className={'flex-1 pl-4'}>{option?.content}</div>;
}

export default UserSettingPanel;

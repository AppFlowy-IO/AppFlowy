import React, { useMemo } from 'react';
import { MenuItem } from './Menu';
import AppearanceSetting from '$app/components/layout/UserSetting/AppearanceSetting';
import LanguageSetting from '$app/components/layout/UserSetting/LanguageSetting';

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
  const { theme, themeMode } = userSettingState;

  const options = useMemo(() => {
    return [
      {
        value: MenuItem.Appearance,
        content: <AppearanceSetting onChange={onChange} theme={theme} themeMode={themeMode} />,
      },
      {
        value: MenuItem.Language,
        icon: <LanguageSetting />,
      },
    ];
  }, [onChange, theme, themeMode]);

  const option = options.find((option) => option.value === selected);

  return <div className={'flex-1 pl-2'}>{option?.content}</div>;
}

export default UserSettingPanel;

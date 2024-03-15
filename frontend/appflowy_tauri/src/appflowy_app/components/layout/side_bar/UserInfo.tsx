import React, { useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { IconButton } from '@mui/material';
import { ReactComponent as SettingIcon } from '$app/assets/settings.svg';
import Tooltip from '@mui/material/Tooltip';
import { useTranslation } from 'react-i18next';
import { SettingsDialog } from '$app/components/settings/SettingsDialog';
import { ProfileAvatar } from '$app/components/_shared/avatar';

function UserInfo() {
  const currentUser = useAppSelector((state) => state.currentUser);
  const [showUserSetting, setShowUserSetting] = useState(false);

  const { t } = useTranslation();

  return (
    <>
      <div className={'flex w-full cursor-pointer select-none items-center justify-between px-4 text-text-title'}>
        <div className={'flex w-full flex-1 items-center gap-2'}>
          <ProfileAvatar width={26} height={26} />
          <span className={'flex-1 text-xs font-semibold'}>{currentUser.displayName}</span>
        </div>

        <Tooltip disableInteractive={true} title={t('settings.menu.open')}>
          <IconButton
            size={'small'}
            onClick={() => {
              setShowUserSetting(!showUserSetting);
            }}
          >
            <SettingIcon className={'text-text-title'} />
          </IconButton>
        </Tooltip>
      </div>

      {showUserSetting && <SettingsDialog open={showUserSetting} onClose={() => setShowUserSetting(false)} />}
    </>
  );
}

export default UserInfo;

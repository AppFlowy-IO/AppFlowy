import React, { useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { Avatar, IconButton } from '@mui/material';
import PersonOutline from '@mui/icons-material/PersonOutline';
import UserSetting from '../user_setting/UserSetting';
import { ReactComponent as SettingIcon } from '$app/assets/settings.svg';
import Tooltip from '@mui/material/Tooltip';
import { useTranslation } from 'react-i18next';

function UserInfo() {
  const currentUser = useAppSelector((state) => state.currentUser);
  const [showUserSetting, setShowUserSetting] = useState(false);

  const { t } = useTranslation();

  return (
    <>
      <div className={'flex w-full cursor-pointer select-none items-center justify-between px-4 text-text-title'}>
        <div className={'flex w-full flex-1 items-center gap-1'}>
          <Avatar
            sx={{
              width: 26,
              height: 26,
              backgroundColor: 'var(--fill-list-active)',
            }}
            className={'text-xs font-bold text-text-title'}
            variant={'circular'}
          >
            {currentUser.displayName ? currentUser.displayName[0] : <PersonOutline />}
          </Avatar>
          <span className={'ml-2 flex-1 text-xs'}>{currentUser.displayName}</span>
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

      <UserSetting open={showUserSetting} onClose={() => setShowUserSetting(false)} />
    </>
  );
}

export default UserInfo;

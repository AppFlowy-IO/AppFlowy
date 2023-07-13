import React, { useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { Avatar } from '@mui/material';
import PersonOutline from '@mui/icons-material/PersonOutline';
import ArrowDropDown from '@mui/icons-material/ArrowDropDown';
import UserSetting from '../UserSetting';

function UserInfo() {
  const currentUser = useAppSelector((state) => state.currentUser);
  const [showUserSetting, setShowUserSetting] = useState(false);

  return (
    <>
      <div
        onClick={(e) => {
          e.stopPropagation();
          setShowUserSetting(!showUserSetting);
        }}
        className={'flex cursor-pointer items-center px-6 text-text-title'}
      >
        <Avatar
          sx={{
            width: 23,
            height: 23,
          }}
          className={'text-text-title'}
          variant={'rounded'}
        >
          <PersonOutline />
        </Avatar>
        <span className={'ml-2 text-sm'}>{currentUser.displayName}</span>
        <button className={'ml-2 rounded hover:bg-fill-list-hover'}>
          <ArrowDropDown />
        </button>
      </div>

      <UserSetting open={showUserSetting} onClose={() => setShowUserSetting(false)} />
    </>
  );
}

export default UserInfo;

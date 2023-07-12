import { useAppSelector } from '$app/stores/store';
import UserSetting from '$app/components/layout/UserSetting';
import { useState } from 'react';
import PersonOutline from '@mui/icons-material/PersonOutline';
import { Avatar, IconButton } from '@mui/material';
import ArrowDropDown from '@mui/icons-material/ArrowDropDown';

export const WorkspaceUser = () => {
  const currentUser = useAppSelector((state) => state.currentUser);
  const [showUserSetting, setShowUserSetting] = useState(false);

  return (
    <div className={'flex items-center justify-between px-2 py-2'}>
      <div
        onClick={(e) => {
          e.stopPropagation();
          setShowUserSetting(!showUserSetting);
        }}
        className={'flex cursor-pointer items-center pl-4 text-text-title'}
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
        <span className={'ml-2'}>{currentUser.displayName}</span>
        <button className={'ml-1 rounded hover:bg-fill-list-hover'}>
          <ArrowDropDown />
        </button>
      </div>

      <UserSetting open={showUserSetting} onClose={() => setShowUserSetting(false)} />
    </div>
  );
};

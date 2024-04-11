import { useAuth } from '@/components/auth/auth.hooks';
import { Button } from '@mui/material';
import Avatar from '@mui/material/Avatar';
import React, { useMemo } from 'react';
import LogoutOutlined from '@mui/icons-material/LogoutOutlined';

function Header () {
  const { logout, currentUser } = useAuth();

  const user = useMemo(() => currentUser?.user, [currentUser]);

  return (
    <div className={'appflowy-top-bar flex h-[64px] select-none border-b border-line-divider p-4'}>
      <div className={'flex flex-1 items-center justify-between'}>
        <div className={'flex gap-2 items-center justify-between'}>
          <Avatar>AppFlowy</Avatar>
          Page Name
        </div>
        <div className={'flex-1 flex items-center justify-center'}>
          <Button>Download Desktop</Button>
        </div>
        {
          user ? (
            <div className={'flex items-center'}>
              <Avatar src={user.iconUrl} />
              {user.email}
              <Button onClick={logout}><LogoutOutlined /></Button>
            </div>
          ) : (
            <Button>Login</Button>
          )
        }
      </div>
    </div>
  );
}

export default Header;
import React, { useCallback, useMemo } from 'react';
import { LogoutSvg } from '$app/components/_shared/svg/LogoutSvg';
import { useAuth } from '$app/components/auth/auth.hooks';
import MenuItem from '@mui/material/MenuItem';
import { useTranslation } from 'react-i18next';

function MoreMenu({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
  const { logout } = useAuth();
  const onSignOutClick = useCallback(async () => {
    await logout();
    onClose();
  }, [onClose, logout]);

  const items = useMemo(() => {
    return [
      {
        title: t('button.signOut'),
        icon: (
          <i className={'block h-5 w-5 flex-shrink-0'}>
            <LogoutSvg></LogoutSvg>
          </i>
        ),
        onClick: onSignOutClick,
      },
    ];
  }, [onSignOutClick, t]);

  return (
    <>
      {items.map((item, index) => {
        return (
          <MenuItem key={index} onClick={item.onClick}>
            <div className={'flex items-center gap-2'}>
              {item.icon}
              <span className={'flex-shrink-0'}>{item.title}</span>
            </div>
          </MenuItem>
        );
      })}
    </>
  );
}

export default MoreMenu;

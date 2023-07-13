import React from 'react';
import { IconButton } from '@mui/material';
import { ShowMenuSvg } from '$app/components/_shared/svg/ShowMenuSvg';
import { HideMenuSvg } from '$app/components/_shared/svg/HideMenuSvg';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { sidebarActions } from '$app_reducers/sidebar/slice';

function CollapseMenuButton() {
  const isCollapsed = useAppSelector((state) => state.sidebar.isCollapsed);
  const dispatch = useAppDispatch();
  const handleClick = () => {
    dispatch(sidebarActions.toggleCollapse());
  };

  return (
    <IconButton className={'h-6 w-6 p-2'} size={'small'} onClick={handleClick}>
      {isCollapsed ? <ShowMenuSvg /> : <HideMenuSvg />}
    </IconButton>
  );
}

export default CollapseMenuButton;

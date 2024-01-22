import React from 'react';
import { IconButton } from '@mui/material';

import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { sidebarActions } from '$app_reducers/sidebar/slice';
import { ReactComponent as LeftSvg } from '$app/assets/left.svg';
import { ReactComponent as RightSvg } from '$app/assets/right.svg';

function CollapseMenuButton() {
  const isCollapsed = useAppSelector((state) => state.sidebar.isCollapsed);
  const dispatch = useAppDispatch();
  const handleClick = () => {
    dispatch(sidebarActions.toggleCollapse());
  };

  return (
    <IconButton size={'small'} className={'font-bold'} onClick={handleClick}>
      {isCollapsed ? <RightSvg /> : <LeftSvg />}
    </IconButton>
  );
}

export default CollapseMenuButton;

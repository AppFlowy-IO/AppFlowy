import React, { useCallback, useEffect, useMemo } from 'react';
import { IconButton, Tooltip } from '@mui/material';

import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { sidebarActions } from '$app_reducers/sidebar/slice';
import { ReactComponent as ShowMenuIcon } from '$app/assets/show-menu.svg';
import { useTranslation } from 'react-i18next';
import { getModifier } from '$app/utils/get_modifier';
import isHotkey from 'is-hotkey';

function CollapseMenuButton() {
  const isCollapsed = useAppSelector((state) => state.sidebar.isCollapsed);
  const dispatch = useAppDispatch();
  const handleClick = useCallback(() => {
    dispatch(sidebarActions.toggleCollapse());
  }, [dispatch]);

  const { t } = useTranslation();

  const title = useMemo(() => {
    return (
      <div className={'flex flex-col gap-1 text-xs'}>
        <div>{isCollapsed ? t('sideBar.openSidebar') : t('sideBar.closeSidebar')}</div>
        <div>{`${getModifier()} + \\`}</div>
      </div>
    );
  }, [isCollapsed, t]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (isHotkey('mod+\\', e)) {
        e.preventDefault();
        handleClick();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleClick]);

  return (
    <Tooltip title={title}>
      <IconButton size={'small'} className={'h-[20px] w-[20px] font-bold text-text-title'} onClick={handleClick}>
        <ShowMenuIcon className={`transform ${isCollapsed ? '' : 'rotate-180'}`} />
      </IconButton>
    </Tooltip>
  );
}

export default CollapseMenuButton;

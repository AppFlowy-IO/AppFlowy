import { Chip, Divider } from '@mui/material';
import React, { MouseEventHandler, useCallback, useEffect, useState } from 'react';
import { SortMenu } from './SortMenu';
import { useTranslation } from 'react-i18next';
import { ReactComponent as SortSvg } from '$app/assets/sort.svg';
import { ReactComponent as DropDownSvg } from '$app/assets/dropdown.svg';
import { useDatabase } from '$app/components/database';

export const Sorts = () => {
  const { t } = useTranslation();
  const { sorts } = useDatabase();

  const showSorts = sorts && sorts.length > 0;
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);

  const handleClick = useCallback<MouseEventHandler<HTMLElement>>((event) => {
    setAnchorEl(event.currentTarget);
  }, []);

  const label = (
    <div className={'flex items-center justify-center'}>
      <SortSvg className={'mr-1.5 h-4 w-4'} />
      {t('grid.settings.sort')}
      <DropDownSvg className={'ml-1.5 h-6 w-6'} />
    </div>
  );

  const menuOpen = Boolean(anchorEl);

  useEffect(() => {
    if (!showSorts) {
      setAnchorEl(null);
    }
  }, [showSorts]);

  if (!showSorts) return null;

  return (
    <>
      <Chip clickable variant='outlined' label={label} onClick={handleClick} />
      <Divider className={'mx-2'} orientation='vertical' flexItem />
      <SortMenu open={menuOpen} anchorEl={anchorEl} onClose={() => setAnchorEl(null)} />
    </>
  );
};

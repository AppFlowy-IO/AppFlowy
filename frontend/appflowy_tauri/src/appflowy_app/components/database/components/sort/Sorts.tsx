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
    <div className={'flex items-center justify-center gap-1'}>
      <SortSvg className={'h-4 w-4'} />
      {t('grid.settings.sort')}
      <DropDownSvg className={'h-5 w-5'} />
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
    <div className={'text-text-title'}>
      <Chip clickable variant='outlined' label={label} onClick={handleClick} />
      <Divider className={'mx-2'} orientation='vertical' flexItem />
      <SortMenu open={menuOpen} anchorEl={anchorEl} onClose={() => setAnchorEl(null)} />
    </div>
  );
};

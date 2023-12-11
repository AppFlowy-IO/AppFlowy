import React, { useState } from 'react';
import { IconButton, Menu, MenuItem } from '@mui/material';
import { ReactComponent as MoreSvg } from '$app/assets/details.svg';
import { Filter } from '$app/components/database/application';
import { useTranslation } from 'react-i18next';
import { deleteFilter } from '$app/components/database/application/filter/filter_service';
import { useViewId } from '$app/hooks';

function FilterActions({ filter }: { filter: Filter }) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);
  const onClose = () => {
    setAnchorEl(null);
  };

  const onDelete = async () => {
    try {
      await deleteFilter(viewId, filter);
    } catch (e) {
      // toast.error(e.message);
    }
  };

  return (
    <>
      <IconButton
        onClick={(e) => {
          setAnchorEl(e.currentTarget);
        }}
        className={'mx-2 my-1.5'}
      >
        <MoreSvg />
      </IconButton>
      <Menu keepMounted={false} open={open} anchorEl={anchorEl} onClose={onClose}>
        <MenuItem onClick={onDelete}>{t('grid.settings.deleteFilter')}</MenuItem>
      </Menu>
    </>
  );
}

export default FilterActions;

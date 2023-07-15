import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { Drawer, IconButton } from '@mui/material';
import { Details2Svg } from '$app/components/_shared/svg/Details2Svg';
import { LogoutOutlined } from '@mui/icons-material';
import Tooltip from '@mui/material/Tooltip';
import MoreOptions from '$app/components/layout/TopBar/MoreOptions';
import { useMoreOptionsConfig } from '$app/components/layout/TopBar/MoreOptions.hooks';

function MoreButton() {
  const { t } = useTranslation();
  const [open, setOpen] = React.useState(false);
  const toggleDrawer = useCallback((open: boolean) => {
    setOpen(open);
  }, []);
  const { showMoreButton } = useMoreOptionsConfig();

  if (!showMoreButton) return null;
  return (
    <>
      <Tooltip placement={'bottom-end'} title={t('moreAction.moreOptions')}>
        <IconButton onClick={(e) => toggleDrawer(true)} className={'h-8 w-8 text-icon-primary'}>
          <Details2Svg />
        </IconButton>
      </Tooltip>
      <Drawer anchor={'right'} open={open} onClose={() => toggleDrawer(false)}>
        <MoreOptions />
      </Drawer>
    </>
  );
}

export default MoreButton;

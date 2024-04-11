import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { Drawer, IconButton } from '@mui/material';
import { ReactComponent as Details2Svg } from '$app/assets/details.svg';
import Tooltip from '@mui/material/Tooltip';
import MoreOptions from '$app/components/layout/top_bar/MoreOptions';
import { useMoreOptionsConfig } from '$app/components/layout/top_bar/MoreOptions.hooks';

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
        <IconButton onClick={() => toggleDrawer(true)} className={'text-icon-primary'}>
          <Details2Svg className={'h-8 w-8'} />
        </IconButton>
      </Tooltip>
      <Drawer anchor={'right'} open={open} onClose={() => toggleDrawer(false)}>
        <MoreOptions />
      </Drawer>
    </>
  );
}

export default MoreButton;

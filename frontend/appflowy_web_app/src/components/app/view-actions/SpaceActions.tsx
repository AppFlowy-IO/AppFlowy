import { View } from '@/application/types';
import { Popover } from '@/components/_shared/popover';
import AddPageActions from '@/components/app/view-actions/AddPageActions';
import MoreSpaceActions from '@/components/app/view-actions/MoreSpaceActions';
import { IconButton, Tooltip } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import React from 'react';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { useTranslation } from 'react-i18next';

const popoverProps: Partial<PopoverProps> = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
};

function SpaceActions ({ view }: {
  view: View
}) {
  const { t } = useTranslation();
  const [popoverType, setPopoverType] = React.useState<'more' | 'add'>('more');
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);
  const handleClosePopover = () => {
    setAnchorEl(null);
  };

  return (
    <div
      onClick={e => e.stopPropagation()}
      className={'flex items-center px-2'}
    >
      <Tooltip
        disableInteractive={true}
        title={t('space.manage')}
      >
        <IconButton
          onClick={e => {
            e.stopPropagation();
            setPopoverType('more');
            setAnchorEl(e.currentTarget);
          }}
          size={'small'}
        >
          <MoreIcon />
        </IconButton>
      </Tooltip>
      <Tooltip
        disableInteractive={true}
        title={t('sideBar.addAPage')}
      >
        <IconButton
          onClick={e => {
            e.stopPropagation();
            setPopoverType('add');
            setAnchorEl(e.currentTarget);
          }}
          size={'small'}
        >
          <AddIcon />
        </IconButton>
      </Tooltip>
      <Popover
        {...popoverProps}
        keepMounted={false}
        open={open}
        anchorEl={anchorEl}
        onClose={handleClosePopover}
      >
        {popoverType === 'more' ? <MoreSpaceActions view={view} /> : <AddPageActions view={view} />}
      </Popover>
    </div>
  );
}

export default SpaceActions;
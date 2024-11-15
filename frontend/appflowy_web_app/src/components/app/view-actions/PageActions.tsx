import { View, ViewLayout } from '@/application/types';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { Popover } from '@/components/_shared/popover';
import AddPageActions from '@/components/app/view-actions/AddPageActions';
import MorePageActions from '@/components/app/view-actions/MorePageActions';
import { IconButton, Tooltip } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import React from 'react';
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

function PageActions ({ view }: {
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
        title={t('menuAppHeader.moreButtonToolTip')}
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
      {view.layout === ViewLayout.Document && <Tooltip
        disableInteractive={true}
        title={t('menuAppHeader.addPageTooltip')}
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
      </Tooltip>}

      <Popover
        {...popoverProps} keepMounted={false}
        open={open}
        anchorEl={anchorEl}
        onClose={handleClosePopover}
      >
        {popoverType === 'more' ? <MorePageActions
          view={view}
          onClose={() => {
            handleClosePopover();
          }}
        /> : <AddPageActions view={view} />}
      </Popover>
    </div>
  );
}

export default PageActions;
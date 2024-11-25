import DocumentInfo from '@/components/app/header/DocumentInfo';
import MoreActionsContent from './MoreActionsContent';
import React from 'react';
import { Popover } from '@/components/_shared/popover';
import { IconButton } from '@mui/material';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';

function MoreActions ({
  viewId,
  onDeleted,
}: {
  viewId: string;
  onDeleted?: () => void;
}) {

  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const open = Boolean(anchorEl);

  return (
    <>
      <IconButton onClick={handleClick}>
        <MoreIcon className={'text-text-caption'} />
      </IconButton>
      {open && (
        <Popover
          anchorOrigin={{
            vertical: 'bottom',
            horizontal: 'right',
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'right',
          }}
          open={open}
          anchorEl={anchorEl}
          onClose={handleClose}
          slotProps={{ root: { className: 'text-sm' } }}
          sx={{
            '& .MuiPopover-paper': {
              width: '268px',
              margin: '10px',
              padding: '12px',
              display: 'flex',
              flexDirection: 'column',
              gap: '8px',
            },
          }}
        >
          <MoreActionsContent
            itemClicked={() => {
              handleClose();
            }}
            onDeleted={onDeleted}
            viewId={viewId}
            movePopoverOrigins={{
              transformOrigin: {
                vertical: 'top',
                horizontal: 'right',
              },
              anchorOrigin: {
                vertical: 'top',
                horizontal: -20,
              },
            }}
          />
          {open && <DocumentInfo viewId={viewId} />}
        </Popover>
      )}
    </>
  );
}

export default MoreActions;
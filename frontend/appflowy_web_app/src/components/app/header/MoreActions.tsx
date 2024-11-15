import { useAppView, useAppWordCount } from '@/components/app/app.hooks';
import dayjs from 'dayjs';
import { useTranslation } from 'react-i18next';
import MoreActionsContent from './MoreActionsContent';
import React from 'react';
import { Popover } from '@/components/_shared/popover';
import { Divider, IconButton } from '@mui/material';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';

function MoreActions ({
  viewId,
}: {
  viewId: string;
}) {
  const { t } = useTranslation();
  const view = useAppView(viewId);
  const wordCount = useAppWordCount(viewId);
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
          <Divider />
          <div className={'flex flex-col gap-1 text-text-caption text-xs '}>
            <div
              className={'px-[10px]'}
            >
              {t('moreAction.wordCountLabel')}{wordCount?.words}
            </div>
            <div className={'px-[10px]'}>
              {t('moreAction.charCountLabel')}{wordCount?.characters}
            </div>
            <div className={'px-[10px]'}>
              {t('moreAction.createdAtLabel')}{dayjs(view?.created_at).format('MMM D, YYYY hh:mm')}
            </div>
          </div>

        </Popover>
      )}
    </>
  );
}

export default MoreActions;
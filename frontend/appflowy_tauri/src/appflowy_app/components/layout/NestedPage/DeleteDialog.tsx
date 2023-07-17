import React, { useState } from 'react';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import Dialog from '@mui/material/Dialog';
import { useTranslation } from 'react-i18next';
import TextField from '@mui/material/TextField';
import { Button, DialogActions } from '@mui/material';
import { ViewLayoutPB } from '@/services/backend';

function DeleteDialog({
  layout,
  open,
  onClose,
  onOk,
}: {
  layout: ViewLayoutPB;
  open: boolean;
  onClose: () => void;
  onOk: () => Promise<void>;
}) {
  const { t } = useTranslation();

  const pageType = {
    [ViewLayoutPB.Document]: t('document.menuName'),
    [ViewLayoutPB.Grid]: t('grid.menuName'),
    [ViewLayoutPB.Board]: t('board.menuName'),
    [ViewLayoutPB.Calendar]: t('calendar.menuName'),
  }[layout];

  return (
    <Dialog keepMounted={false} onMouseDown={(e) => e.stopPropagation()} open={open} onClose={onClose}>
      <DialogContent className={'flex w-[540px] flex-col items-center justify-center'}>
        <div className={'text-md m-2 font-bold'}>
          {t('views.deleteContentTitle', {
            pageType,
          })}
        </div>
        <div className={'m-1 text-sm text-text-caption'}>
          {t('views.deleteContentCaption', {
            pageType,
          })}
        </div>
      </DialogContent>
      <DialogActions>
        <Button variant={'outlined'} onClick={onClose}>
          {t('button.Cancel')}
        </Button>
        <Button
          variant={'contained'}
          onClick={async () => {
            try {
              await onOk();
              onClose();
            } catch (e) {}
          }}
        >
          {t('button.delete')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

export default DeleteDialog;

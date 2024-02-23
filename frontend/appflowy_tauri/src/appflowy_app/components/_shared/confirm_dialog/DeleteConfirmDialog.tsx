import React, { useCallback } from 'react';
import DialogContent from '@mui/material/DialogContent';
import { Button, DialogActions, Divider } from '@mui/material';
import Dialog from '@mui/material/Dialog';
import { useTranslation } from 'react-i18next';
import { Log } from '$app/utils/log';

interface Props {
  open: boolean;
  title: string;
  subtitle: string;
  onOk: () => Promise<void>;
  onClose: () => void;
}

function DeleteConfirmDialog({ open, title, subtitle, onOk, onClose }: Props) {
  const { t } = useTranslation();

  const onDone = useCallback(async () => {
    try {
      await onOk();
      onClose();
    } catch (e) {
      Log.error(e);
    }
  }, [onClose, onOk]);

  return (
    <Dialog
      keepMounted={false}
      onKeyDown={(e) => {
        if (e.key === 'Escape') {
          e.preventDefault();
          e.stopPropagation();
          onClose();
        }

        if (e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          void onDone();
        }
      }}
      onMouseDown={(e) => e.stopPropagation()}
      open={open}
      onClose={onClose}
    >
      <DialogContent className={'flex w-[340px] flex-col items-center justify-center gap-4'}>
        <div className={'text-md font-medium'}>{title}</div>
        {subtitle && <div className={'m-1 text-sm text-text-caption'}>{subtitle}</div>}
      </DialogContent>
      <Divider className={'mb-4'} />
      <DialogActions className={'p-4 pt-0'}>
        <Button variant={'outlined'} onClick={onClose}>
          {t('button.cancel')}
        </Button>
        <Button variant={'contained'} onClick={onDone}>
          {t('button.delete')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

export default DeleteConfirmDialog;

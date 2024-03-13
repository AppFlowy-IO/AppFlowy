import React, { useCallback } from 'react';
import DialogContent from '@mui/material/DialogContent';
import { Button, DialogProps } from '@mui/material';
import Dialog from '@mui/material/Dialog';
import { useTranslation } from 'react-i18next';
import { Log } from '$app/utils/log';

interface Props extends DialogProps {
  open: boolean;
  title: string;
  subtitle?: string;
  onOk?: () => Promise<void>;
  onClose: () => void;
  onCancel?: () => void;
  okText?: string;
  cancelText?: string;
  container?: HTMLElement | null;
}

function DeleteConfirmDialog({ open, title, onOk, onCancel, onClose, okText, cancelText, container, ...props }: Props) {
  const { t } = useTranslation();

  const onDone = useCallback(async () => {
    try {
      await onOk?.();
      onClose();
    } catch (e) {
      Log.error(e);
    }
  }, [onClose, onOk]);

  return (
    <Dialog
      container={container}
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
      {...props}
    >
      <DialogContent className={'w-[320px]'}>
        {title}
        <div className={'flex w-full flex-col gap-2 pb-2 pt-4'}>
          <Button className={'w-full'} variant={'outlined'} color={'error'} onClick={onDone}>
            {okText ?? t('button.delete')}
          </Button>
          <Button
            className={'w-full'}
            variant={'outlined'}
            color={'inherit'}
            onClick={() => {
              onCancel?.();
              onClose();
            }}
          >
            {cancelText ?? t('button.cancel')}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

export default DeleteConfirmDialog;

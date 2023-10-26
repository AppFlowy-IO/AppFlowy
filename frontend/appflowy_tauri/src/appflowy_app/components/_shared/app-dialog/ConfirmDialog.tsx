import React from 'react';
import DialogContent from '@mui/material/DialogContent';
import { Button, DialogActions } from '@mui/material';
import Dialog from '@mui/material/Dialog';
import { useTranslation } from 'react-i18next';

interface Props {
  open: boolean;
  title: string;
  subtitle: string;
  onOk: () => Promise<void>;
  onClose: () => void;
}

function ConfirmDialog({ open, title, subtitle, onOk, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <Dialog keepMounted={false} onMouseDown={(e) => e.stopPropagation()} open={open} onClose={onClose}>
      <DialogContent className={'flex w-[540px] flex-col items-center justify-center'}>
        <div className={'text-md m-2 font-bold'}>{title}</div>
        <div className={'m-1 text-sm text-text-caption'}>{subtitle}</div>
      </DialogContent>
      <DialogActions>
        <Button variant={'outlined'} onClick={onClose}>
          {t('button.cancel')}
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

export default ConfirmDialog;

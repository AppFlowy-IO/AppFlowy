import React, { useState } from 'react';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import Dialog from '@mui/material/Dialog';
import { useTranslation } from 'react-i18next';
import TextField from '@mui/material/TextField';
import { Button, DialogActions } from '@mui/material';

function RenameDialog({
  defaultValue,
  open,
  onClose,
  onOk,
}: {
  defaultValue: string;
  open: boolean;
  onClose: () => void;
  onOk: (val: string) => void;
}) {
  const { t } = useTranslation();
  const [value, setValue] = useState(defaultValue);

  return (
    <Dialog keepMounted={false} onMouseDown={(e) => e.stopPropagation()} open={open} onClose={onClose}>
      <DialogTitle>{t('menuAppHeader.renameDialog')}</DialogTitle>
      <DialogContent className={'flex w-[540px]'}>
        <TextField
          autoFocus
          value={value}
          onChange={(e) => {
            setValue(e.target.value);
          }}
          margin='dense'
          fullWidth
          variant='standard'
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>{t('button.Cancel')}</Button>
        <Button
          onClick={() => {
            onOk(value);
          }}
        >
          {t('button.OK')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

export default RenameDialog;

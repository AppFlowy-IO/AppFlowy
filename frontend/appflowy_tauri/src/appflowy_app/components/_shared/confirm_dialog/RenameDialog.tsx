import React, { useCallback, useEffect, useState } from 'react';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import Dialog from '@mui/material/Dialog';
import { useTranslation } from 'react-i18next';
import TextField from '@mui/material/TextField';
import { Button, DialogActions, Divider } from '@mui/material';

function RenameDialog({
  defaultValue,
  open,
  onClose,
  onOk,
}: {
  defaultValue: string;
  open: boolean;
  onClose: () => void;
  onOk: (val: string) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [value, setValue] = useState(defaultValue);
  const [error, setError] = useState(false);

  useEffect(() => {
    setValue(defaultValue);
    setError(false);
  }, [defaultValue]);

  const onDone = useCallback(async () => {
    try {
      await onOk(value);
      onClose();
    } catch (e) {
      setError(true);
    }
  }, [onClose, onOk, value]);

  return (
    <Dialog keepMounted={false} onMouseDown={(e) => e.stopPropagation()} open={open} onClose={onClose}>
      <DialogTitle className={'pb-2'}>{t('menuAppHeader.renameDialog')}</DialogTitle>
      <DialogContent className={'flex'}>
        <TextField
          error={error}
          autoFocus
          spellCheck={false}
          value={value}
          placeholder={t('dialogCreatePageNameHint')}
          onKeyDown={(e) => {
            e.stopPropagation();
            if (e.key === 'Enter') {
              e.preventDefault();
              void onDone();
            }

            if (e.key === 'Escape') {
              e.preventDefault();
              onClose();
            }
          }}
          onChange={(e) => {
            setValue(e.target.value);
          }}
          margin='dense'
          fullWidth
          variant='standard'
        />
      </DialogContent>
      <Divider className={'mb-1'} />
      <DialogActions className={'mb-1 px-4'}>
        <Button color={'inherit'} variant={'outlined'} onClick={onClose}>
          {t('button.cancel')}
        </Button>
        <Button variant={'contained'} onClick={onDone}>
          {t('button.ok')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

export default RenameDialog;

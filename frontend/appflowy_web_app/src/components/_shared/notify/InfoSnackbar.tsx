import React, { forwardRef } from 'react';
import { Button, IconButton, Paper } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';
import { CustomContentProps, SnackbarContent } from 'notistack';

export interface InfoProps {
  onOk?: () => void;
  okText?: string;
  title?: string;
  message?: JSX.Element | string;
  onClose?: () => void;
  autoHideDuration?: number | null;
}

export type InfoSnackbarProps = InfoProps & CustomContentProps;

const InfoSnackbar = forwardRef<HTMLDivElement, InfoSnackbarProps>(({ onOk, okText, title, message, onClose }, ref) => {
  const { t } = useTranslation();

  return (
    <SnackbarContent ref={ref}>
      <Paper className={'relative flex flex-col gap-4 p-5'}>
        <div className={'flex w-full items-center justify-between text-base font-medium'}>
          <div className={'flex-1 text-left '}>{title}</div>
          <div className={'relative -right-1.5'}>
            <IconButton size={'small'} color={'inherit'} className={'h-6 w-6'} onClick={onClose}>
              <CloseIcon className={'h-4 w-4'} />
            </IconButton>
          </div>
        </div>

        <div className={'flex-1'}>{message}</div>
        <div className={'flex w-full justify-end gap-4'}>
          <Button color={'primary'} variant={'contained'} onClick={onOk}>
            {okText || t('button.ok')}
          </Button>
        </div>
      </Paper>
    </SnackbarContent>
  );
});

export default InfoSnackbar;

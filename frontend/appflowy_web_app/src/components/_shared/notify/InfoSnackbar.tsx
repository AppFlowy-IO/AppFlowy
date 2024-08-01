import { notify } from '@/components/_shared/notify/index';
import React, { forwardRef } from 'react';
import { Button, IconButton, Paper } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';
import { CustomContentProps, SnackbarContent } from 'notistack';
import { ReactComponent as CheckCircle } from '@/assets/check_circle.svg';
import { ReactComponent as ErrorOutline } from '@/assets/error_outline.svg';
import { ReactComponent as WarningAmber } from '@/assets/warning_amber.svg';

export interface InfoProps {
  onOk?: () => void;
  okText?: string;
  title?: string;
  message?: JSX.Element | string;
  onClose?: () => void;
  autoHideDuration?: number | null;
  type?: 'success' | 'info' | 'warning' | 'error';
  showActions?: boolean;
}

export type InfoSnackbarProps = InfoProps & CustomContentProps;

const InfoSnackbar = forwardRef<HTMLDivElement, InfoSnackbarProps>(
  ({ showActions = true, type = 'info', onOk, okText, title, message, onClose }, ref) => {
    const { t } = useTranslation();

    const handleClose = () => {
      onClose?.();
      notify.clear();
    };

    return (
      <SnackbarContent ref={ref}>
        <Paper className={`relative flex flex-col gap-4 border p-4 ${getBorderColor(type)}`}>
          <div className={'flex w-full items-center justify-between text-base font-medium'}>
            <div className={'flex flex-1 items-center gap-2 text-left font-semibold'}>
              {getIcon(type)}
              <div>{title}</div>
            </div>
            <div className={'relative -right-1.5'}>
              <IconButton size={'small'} color={'inherit'} className={'h-6 w-6'} onClick={handleClose}>
                <CloseIcon className={'h-4 w-4'} />
              </IconButton>
            </div>
          </div>

          <div className={'flex-1 pr-10'}>{message}</div>
          {showActions && (
            <div className={'flex w-full justify-end gap-4'}>
              <Button
                color={'primary'}
                variant={'contained'}
                onClick={() => {
                  onOk?.();
                  handleClose();
                }}
                className={`${getButtonBgColor(type)} ${getButtonHoverBgColor(type)}}`}
              >
                {okText || t('button.ok')}
              </Button>
            </div>
          )}
        </Paper>
      </SnackbarContent>
    );
  }
);

export default InfoSnackbar;

function getIcon(type: 'success' | 'info' | 'warning' | 'error') {
  switch (type) {
    case 'success':
      return <CheckCircle className={'h-6 w-6 text-[var(--function-success)]'} />;
    case 'info':
      return '';
    case 'warning':
      return <WarningAmber className={'h-6 w-6 text-[var(--function-warning)]'} />;
    case 'error':
      return <ErrorOutline className={'h-6 w-6 text-[var(--function-error)]'} />;
  }
}

function getButtonBgColor(type: 'success' | 'info' | 'warning' | 'error') {
  switch (type) {
    case 'success':
      return 'bg-[var(--function-success)]';
    case 'info':
      return '';
    case 'warning':
      return 'bg-[var(--function-warning)]';
    case 'error':
      return 'bg-[var(--function-error)]';
  }
}

function getButtonHoverBgColor(type: 'success' | 'info' | 'warning' | 'error') {
  switch (type) {
    case 'success':
      return 'hover:bg-[var(--function-success-hover)]';
    case 'info':
      return '';
    case 'warning':
      return 'hover:bg-[var(--function-warning-hover)]';
    case 'error':
      return 'hover:bg-[var(--function-error-hover)]';
  }
}

function getBorderColor(type: 'success' | 'info' | 'warning' | 'error') {
  switch (type) {
    case 'success':
      return 'border-[var(--function-success)]';
    case 'info':
      return 'border-transparent';
    case 'warning':
      return 'border-[var(--function-warning)]';
    case 'error':
      return 'border-[var(--function-error)]';
  }
}

import React from 'react';
import { useTranslation } from 'react-i18next';
import { Button, Dialog, DialogProps, IconButton } from '@mui/material';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';

export interface NormalModalProps extends DialogProps {
  okText?: string;
  cancelText?: string;
  onOk?: () => void;
  onCancel?: () => void;
  danger?: boolean;
  title?: string;
}

export function NormalModal({
  okText,
  title,
  cancelText,
  onOk,
  onCancel,
  danger,
  children,
  ...dialogProps
}: NormalModalProps) {
  const { t } = useTranslation();
  const modalOkText = okText || t('button.ok');
  const modalCancelText = cancelText || t('button.cancel');
  const buttonColor = danger ? 'var(--function-error)' : undefined;

  return (
    <Dialog {...dialogProps}>
      <div className={'relative flex flex-col gap-4 p-5'}>
        <div className={'flex w-full items-center justify-between text-base font-medium'}>
          <div className={'flex-1  text-center '}>{title}</div>
          <div className={'relative -right-1.5'}>
            <IconButton size={'small'} color={'inherit'} className={'h-8 w-8'} onClick={onCancel}>
              <CloseIcon className={'h-8 w-8'} />
            </IconButton>
          </div>
        </div>

        <div className={'flex-1'}>{children}</div>
        <div className={'flex w-full justify-end gap-4'}>
          <Button color={'inherit'} variant={'outlined'} onClick={onCancel}>
            {modalCancelText}
          </Button>
          <Button color={'primary'} variant={'contained'} style={{ backgroundColor: buttonColor }} onClick={onOk}>
            {modalOkText}
          </Button>
        </div>
      </div>
    </Dialog>
  );
}

export default NormalModal;

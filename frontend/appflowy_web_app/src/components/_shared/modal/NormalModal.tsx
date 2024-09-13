import React from 'react';
import { useTranslation } from 'react-i18next';
import { Button, ButtonProps, CircularProgress, Dialog, DialogProps, IconButton } from '@mui/material';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
export interface NormalModalProps extends DialogProps {
  okText?: string;
  cancelText?: string;
  onOk?: () => void;
  onCancel?: () => void;
  danger?: boolean;
  onClose?: () => void;
  title: string | React.ReactNode;
  okButtonProps?: ButtonProps;
  cancelButtonProps?: ButtonProps;
  okLoading?: boolean;
  closable?: boolean;
}

export function NormalModal ({
  okText,
  title,
  cancelText,
  onOk,
  onCancel,
  danger,
  onClose,
  children,
  okButtonProps,
  cancelButtonProps,
  okLoading,
  closable = true,
  ...dialogProps
}: NormalModalProps) {
  const { t } = useTranslation();
  const modalOkText = okText || t('button.ok');
  const modalCancelText = cancelText || t('button.cancel');

  return (
    <Dialog
      onKeyDown={(e) => {
        if (e.key === 'Escape' && closable) {
          onClose?.();
        }
      }}
      {...dialogProps}
    >
      <div className={'relative flex flex-col gap-4 p-5'}>
        <div className={'flex w-full items-center justify-between text-base font-medium'}>
          <div className={'flex-1 text-center '}>{title}</div>
          {closable && <div className={'relative -right-1.5'}>
            <IconButton size={'small'} color={'inherit'} className={'h-6 w-6'} onClick={onClose || onCancel}>
              <CloseIcon className={'h-4 w-4'} />
            </IconButton>
          </div>}

        </div>

        <div className={'flex-1'}>{children}</div>
        <div className={'flex w-full justify-end gap-3'}>
          <Button
            color={'inherit'} variant={'outlined'} onClick={() => {
            if (onCancel) {
              onCancel();
            } else {
              onClose?.();
            }
          }} {...cancelButtonProps}>
            {modalCancelText}
          </Button>
          <Button
            color={danger ? 'error' : 'primary'}
            variant={'contained'}

            onClick={() => {
              if (okLoading) return;
              onOk?.();
            }}
            {...okButtonProps}
          >
            {okLoading ? <CircularProgress size={24} /> : modalOkText}
          </Button>
        </div>
      </div>
    </Dialog>
  );
}

export default NormalModal;

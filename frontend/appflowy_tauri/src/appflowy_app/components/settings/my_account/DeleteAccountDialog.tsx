import Dialog, { DialogProps } from '@mui/material/Dialog';
import { useTranslation } from 'react-i18next';
import DialogTitle from '@mui/material/DialogTitle';
import { DialogActions, DialogContentText, IconButton } from '@mui/material';
import Button from '@mui/material/Button';
import DialogContent from '@mui/material/DialogContent';
import { ReactComponent as CloseIcon } from '$app/assets/close.svg';

export const DeleteAccountDialog = (props: DialogProps) => {
  const { t } = useTranslation();

  const handleClose = () => {
    props?.onClose?.({}, 'backdropClick');
  };

  const handleOk = () => {
    //123
  };

  return (
    <Dialog
      {...props}
      PaperProps={{
        className: 'py-8 min-w-[300px] max-w-[500px]',
      }}
      keepMounted={false}
    >
      <DialogTitle className={'text-center'}>{t('newSettings.myAccount.deleteAccount.dialogTitle')}</DialogTitle>
      <DialogContent className={'flex flex-col gap-2 px-16 text-center'}>
        <DialogContentText>{t('newSettings.myAccount.deleteAccount.dialogContent1')}</DialogContentText>
        <DialogContentText>{t('newSettings.myAccount.deleteAccount.dialogContent2')}</DialogContentText>
      </DialogContent>
      <DialogActions className={'flex items-center justify-center'}>
        <div className={'flex flex-1 justify-end'}>
          <Button color={'inherit'} variant={'outlined'} onClick={handleClose}>
            {t('button.cancel')}
          </Button>
        </div>
        <div className={'flex flex-1 justify-start'}>
          <Button color={'error'} variant={'contained'} onClick={handleOk}>
            {t('button.deleteAccount')}
          </Button>
        </div>
      </DialogActions>
      <IconButton onClick={handleClose} className={'absolute right-2 top-2'}>
        <CloseIcon />
      </IconButton>
    </Dialog>
  );
};

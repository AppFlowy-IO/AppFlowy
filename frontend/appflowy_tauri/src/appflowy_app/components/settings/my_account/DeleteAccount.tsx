import { useTranslation } from 'react-i18next';
import { useState } from 'react';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import { DeleteAccountDialog } from '$app/components/settings/my_account/DeleteAccountDialog';

export const DeleteAccount = () => {
  const { t } = useTranslation();

  const [openDialog, setOpenDialog] = useState(false);

  return (
    <div className={'flex w-full items-end'}>
      <div className={'flex flex-1 flex-col gap-2'}>
        <Typography className={'text-text-title'} variant={'subtitle2'}>
          {t('newSettings.myAccount.deleteAccount.title')}
        </Typography>
        <Typography className={'text-text-caption'} variant={'body2'}>
          {t('newSettings.myAccount.deleteAccount.subtitle')}
        </Typography>
      </div>
      <div className={'flex flex-1 items-center justify-end'}>
        <Button
          onClick={() => {
            setOpenDialog(true);
          }}
          disabled
          size={'small'}
          variant={'outlined'}
          color={'error'}
        >
          {t('newSettings.myAccount.deleteAccount.deleteMyAccount')}
        </Button>
      </div>
      <DeleteAccountDialog
        open={openDialog}
        onClose={() => {
          setOpenDialog(false);
        }}
      />
    </div>
  );
};

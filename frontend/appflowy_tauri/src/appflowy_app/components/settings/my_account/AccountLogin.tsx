import { useTranslation } from 'react-i18next';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import { Divider } from '@mui/material';
import { DeleteAccount } from '$app/components/settings/my_account/DeleteAccount';
import { SettingsRoutes } from '$app/components/settings/workplace/const';

export const AccountLogin = ({ onForward }: { onForward?: (route: SettingsRoutes) => void }) => {
  const { t } = useTranslation();

  return (
    <>
      <div className={'w-full'}>
        <Typography className={'mb-4 font-semibold'} variant={'subtitle1'}>
          {t('newSettings.myAccount.accountLogin')}
        </Typography>
        <Button
          onClick={() => {
            onForward?.(SettingsRoutes.LOGIN);
          }}
          variant={'contained'}
        >
          {t('button.login')}
        </Button>
        <Divider className={'my-4'} />
        <DeleteAccount />
      </div>
    </>
  );
};

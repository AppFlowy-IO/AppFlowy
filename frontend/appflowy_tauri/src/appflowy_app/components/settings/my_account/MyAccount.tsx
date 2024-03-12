import { useTranslation } from 'react-i18next';
import Typography from '@mui/material/Typography';
import { Profile } from './Profile';
import { AccountLogin } from './AccountLogin';
import { Divider } from '@mui/material';
import { SettingsRoutes } from '$app/components/settings/workplace/const';

export const MyAccount = ({ onForward }: { onForward?: (route: SettingsRoutes) => void }) => {
  const { t } = useTranslation();

  return (
    <div className={'flex flex-col'}>
      <Typography variant={'h5'} className={'mb-3 font-bold'}>
        {t('newSettings.myAccount.title')}
      </Typography>
      <Typography variant={'body2'} className={'mb-3 text-text-caption'}>
        {t('newSettings.myAccount.subtitle')}
      </Typography>
      <Profile />
      <Divider className={'my-3'} />
      <AccountLogin onForward={onForward} />
    </div>
  );
};

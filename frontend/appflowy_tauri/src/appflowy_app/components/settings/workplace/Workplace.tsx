import { useTranslation } from 'react-i18next';
import Typography from '@mui/material/Typography';
import { WorkplaceDisplay } from '$app/components/settings/workplace/WorkplaceDisplay';
import { Divider } from '@mui/material';
import { Appearance } from '$app/components/settings/workplace/Appearance';

export const Workplace = () => {
  const { t } = useTranslation();

  return (
    <div className={'flex flex-col'}>
      <Typography variant={'h5'} className={'mb-3 font-bold'}>
        {t('newSettings.workplace.title')}
      </Typography>
      <Typography variant={'body2'} className={'mb-3 text-text-caption'}>
        {t('newSettings.workplace.subtitle')}
      </Typography>
      <WorkplaceDisplay />
      <Divider className={'my-3'} />
      <Appearance />
    </div>
  );
};

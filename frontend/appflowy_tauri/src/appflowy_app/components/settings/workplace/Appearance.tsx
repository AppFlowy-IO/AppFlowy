import { useTranslation } from 'react-i18next';
import { ThemeModeSwitch } from '$app/components/settings/workplace/appearance/ThemeModeSwitch';
import Typography from '@mui/material/Typography';
import { Divider } from '@mui/material';
import { LanguageSetting } from '$app/components/settings/workplace/appearance/LanguageSetting';

export const Appearance = () => {
  const { t } = useTranslation();

  return (
    <>
      <Typography className={'mb-2 font-semibold'} variant={'subtitle1'}>
        {t('newSettings.workplace.appearance.name')}
      </Typography>
      <ThemeModeSwitch />
      <Divider className={'my-3'} />
      <LanguageSetting />
    </>
  );
};

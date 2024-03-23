import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import { LoginButtonGroup } from '$app/components/auth/LoginButtonGroup';

export const Login = ({ onBack }: { onBack?: () => void }) => {
  const { t } = useTranslation();

  return (
    <div className={'flex flex-col items-center justify-center gap-4'}>
      <Typography variant={'h4'} className={'mb-3 font-medium'}>
        {t('button.login')}
      </Typography>
      <div className={'flex w-[70%] flex-col items-center gap-4'}>
        <LoginButtonGroup />
        <Button className={'w-full rounded-lg  py-3 text-sm'} onClick={onBack} color={'inherit'} variant={'text'}>
          {t('button.cancel')}
        </Button>
      </div>
    </div>
  );
};

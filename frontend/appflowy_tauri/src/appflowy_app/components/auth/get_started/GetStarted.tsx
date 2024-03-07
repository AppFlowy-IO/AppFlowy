import { AppflowyLogo } from '../../_shared/svg/AppflowyLogo';
import Button from '@mui/material/Button';
import { useLogin } from '$app/components/auth/get_started/useLogin';
import { useTranslation } from 'react-i18next';

export const GetStarted = () => {
  const { onAutoSignInClick } = useLogin();
  const { t } = useTranslation();

  return (
    <>
      <form onSubmit={(e) => e.preventDefault()} method='POST'>
        <div className='relative flex h-screen w-screen flex-col items-center justify-center gap-12 bg-bg-body text-center text-text-title'>
          <div className='flex h-10 w-10 justify-center' id='appflowy'>
            <AppflowyLogo />
          </div>

          <div>
            <span className='text-2xl font-semibold leading-9'>
              {t('signIn.loginTitle').replace('@:appName', 'AppFlowy')}
            </span>
          </div>

          <div id='Get-Started' className='flex w-full max-w-[340px] flex-col ' aria-label='Get-Started'>
            <Button size={'large'} variant={'contained'} onClick={() => onAutoSignInClick()}>
              {t('signUp.getStartedText')}
            </Button>
          </div>
        </div>
      </form>
    </>
  );
};

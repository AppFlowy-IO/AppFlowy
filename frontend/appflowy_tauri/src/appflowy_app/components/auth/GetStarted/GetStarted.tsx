import { t } from 'i18next';
import { AppflowyLogo } from '../../_shared/svg/AppflowyLogo';
import { Button } from '../../_shared/Button';
import { useLogin } from '../Login/Login.hooks';

export const GetStarted = () => {
  const { onAutoSignInClick } = useLogin();
  return (
    <>
      <form onSubmit={(e) => e.preventDefault()} method='POST'>
        <div className='relative flex h-screen w-screen flex-col items-center justify-center gap-12 text-center'>
          <div className='flex h-10 w-10 justify-center' id='appflowy'>
            <AppflowyLogo />
          </div>

          <div>
            <span className='text-2xl font-semibold leading-9'>
              {t('signIn.loginTitle').replace('@:appName', 'AppFlowy')}
            </span>
          </div>

          <div id='Get-Started' className='flex w-full max-w-[340px] flex-col gap-6 ' aria-label='Get-Started' >
            <Button size={'primary'} onClick={() => onAutoSignInClick()} >
              {t('signUp.getStartedText')}
            </Button>
          </div>
        </div>
      </form>
    </>
  );
};

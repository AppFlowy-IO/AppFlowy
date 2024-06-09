import { ReactComponent as AppflowyLogo } from '$app/assets/logo.svg';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { LoginButtonGroup } from '$app/components/auth/LoginButtonGroup';
import { useAuth } from '$app/components/auth/auth.hooks';
import { Log } from '$app/utils/log';

export const Welcome = () => {
  const { signInAsAnonymous } = useAuth();
  const { t } = useTranslation();

  return (
    <>
      <form onSubmit={(e) => e.preventDefault()} method='POST'>
        <div className='relative flex h-screen w-screen flex-col items-center justify-center gap-12 bg-bg-body text-center text-text-title'>
          <div className='flex justify-center' id='appflowy'>
            <AppflowyLogo className={'h-16 w-16'} />
          </div>

          <div>
            <span className='text-2xl font-semibold leading-9'>
              {t('welcomeTo')} {t('appName')}
            </span>
          </div>

          <div id='Get-Started' className='flex w-[340px] flex-col gap-4 ' aria-label='Get-Started'>
            <Button
              size={'large'}
              color={'inherit'}
              className={'border-transparent bg-line-divider py-3'}
              variant={'outlined'}
              onClick={async () => {
                try {
                  await signInAsAnonymous();
                } catch (e) {
                  Log.error(e);
                }
              }}
            >
              {t('signIn.loginStartWithAnonymous')}
            </Button>
            <div className={'flex w-full items-center justify-center gap-2 text-sm'}>
              <div className={'h-px flex-1 bg-line-divider'} />
              {t('signIn.or')}
              <div className={'h-px flex-1 bg-line-divider'} />
            </div>
            <div className={'w-w-full flex items-center justify-center gap-2 text-sm'}>
              <LoginButtonGroup />
            </div>
          </div>
        </div>
      </form>
    </>
  );
};

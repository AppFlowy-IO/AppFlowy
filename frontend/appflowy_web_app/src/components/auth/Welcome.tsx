import { ReactComponent as AppflowyLogo } from '@/assets/logo.svg';
import { useTranslation } from 'react-i18next';
import { LoginButtonGroup } from './LoginButtonGroup';
import { getPlatform } from '@/utils/platform';
import { lazy } from 'react';

const SignInAsAnonymous = lazy(() => import('@/components/tauri/SignInAsAnonymous'));

export const Welcome = () => {

  const { t } = useTranslation();

  return (
    <>
      <form onSubmit={(e) => e.preventDefault()} method="POST">
        <div
          className="relative flex h-screen w-screen flex-col items-center justify-center gap-12 bg-bg-body text-center text-text-title">
          <div className="flex justify-center" id="appflowy">
            <AppflowyLogo className={'h-16 w-16'}/>
          </div>

          <div>
            <span className="text-2xl font-semibold leading-9">
              {t('welcomeTo')} {t('appName')}
            </span>
          </div>

          <div id="Get-Started" className="flex w-[340px] flex-col gap-4 " aria-label="Get-Started">
            {getPlatform().isTauri && <SignInAsAnonymous/>}
            <div className={'w-w-full flex items-center justify-center gap-2 text-sm'}>
              <LoginButtonGroup/>
            </div>
          </div>
        </div>
      </form>
    </>
  );
};

export default Welcome;
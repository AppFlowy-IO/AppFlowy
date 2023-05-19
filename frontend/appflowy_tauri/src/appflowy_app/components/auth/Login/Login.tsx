import { AppflowyLogo } from '../../_shared/svg/AppflowyLogo';
import { EyeClosedSvg } from '../../_shared/svg/EyeClosedSvg';
import { EyeOpenSvg } from '../../_shared/svg/EyeOpenSvg';
import { useLogin } from './Login.hooks';
import { Link } from 'react-router-dom';
import { Button } from '../../_shared/Button';
import { useTranslation } from 'react-i18next';
import { EarthSvg } from '../../_shared/svg/EarthSvg';
import { useState } from 'react';
import { LanguageSelectPopup } from '../../_shared/LanguageSelectPopup';

export const Login = () => {
  const { showPassword, onTogglePassword, onSignInClick, email, setEmail, password, setPassword, authError } =
    useLogin();
  const { t } = useTranslation();
  const [showLanguagePopup, setShowLanguagePopup] = useState(false);

  return (
    <>
      <form onSubmit={(e) => e.preventDefault()} method='POST'>
        <div className='relative flex h-screen w-screen flex-col items-center justify-center gap-12 text-center'>
          <div className='flex h-10 w-10 justify-center'>
            <AppflowyLogo />
          </div>

          <div>
            <span className='text-2xl font-semibold leading-9'>
              {t('signIn.loginTitle').replace('@:appName', 'AppFlowy')}
            </span>
          </div>

          <div className='flex w-full max-w-[340px]  flex-col gap-6 '>
            <input
              type='text'
              className={`input w-full ${authError && 'error'}`}
              placeholder={t('signIn.emailHint') ?? ''}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
            <div className='relative w-full'>
              {/* Password input field */}

              <input
                type={showPassword ? 'text' : 'password'}
                className={`input w-full  !pr-10 ${authError && 'error'}`}
                placeholder={t('signIn.passwordHint') ?? ''}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />

              {/* Show password button */}
              <button
                type='button'
                className='absolute right-0 top-0 flex h-full w-12 items-center justify-center '
                onClick={onTogglePassword}
              >
                <span className='h-6 w-6'>{showPassword ? <EyeClosedSvg /> : <EyeOpenSvg />}</span>
              </button>
            </div>

            <div className='flex justify-center'>
              {/* Forget password link */}
              <Link to={'/auth/confirm-account'}>
                <span className='text-xs text-main-accent hover:text-main-hovered'>{t('signIn.forgotPassword')}</span>
              </Link>
            </div>
          </div>

          <div className='flex w-full max-w-[340px] flex-col gap-6 '>
            <Button size={'primary'} onClick={() => onSignInClick()}>
              {t('signIn.loginButtonText')}
            </Button>

            {/* signup link */}
            <div className='flex justify-center'>
              <span className='text-xs text-gray-400'>
                {t('signIn.dontHaveAnAccount')}
                <Link to={'/auth/signUp'}>
                  <span className='ml-2 text-main-accent hover:text-main-hovered'>{t('signUp.buttonText')}</span>
                </Link>
              </span>
            </div>
          </div>

          <div className={'absolute right-0 top-0 px-12 py-8'}>
            <div className={'relative h-full w-full'}>
              <button className={'h-8 w-8 text-shade-3 hover:text-black'} onClick={() => setShowLanguagePopup(true)}>
                <EarthSvg></EarthSvg>
              </button>
              {showLanguagePopup && (
                <LanguageSelectPopup onClose={() => setShowLanguagePopup(false)}></LanguageSelectPopup>
              )}
            </div>
          </div>
        </div>
      </form>
    </>
  );
};

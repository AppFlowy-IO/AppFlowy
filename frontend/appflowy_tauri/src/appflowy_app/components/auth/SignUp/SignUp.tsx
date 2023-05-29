import { AppflowyLogo } from '../../_shared/svg/AppflowyLogo';
import { EyeClosedSvg } from '../../_shared/svg/EyeClosedSvg';
import { EyeOpenSvg } from '../../_shared/svg/EyeOpenSvg';

import { useSignUp } from './SignUp.hooks';
import { Link } from 'react-router-dom';
import { Button } from '../../_shared/Button';
import { EarthSvg } from '../../_shared/svg/EarthSvg';
import { LanguageSelectPopup } from '../../_shared/LanguageSelectPopup';
import { useTranslation } from 'react-i18next';
import { useState } from 'react';

export const SignUp = () => {
  const {
    showPassword,
    onTogglePassword,
    showConfirmPassword,
    onToggleConfirmPassword,
    onSignUpClick,
    email,
    setEmail,
    displayName,
    setDisplayName,
    password,
    setPassword,
    repeatedPassword,
    setRepeatedPassword,
    authError,
  } = useSignUp();
  const { t } = useTranslation();
  const [showLanguagePopup, setShowLanguagePopup] = useState(false);

  return (
    <form method='POST' onSubmit={(e) => e.preventDefault()}>
      <div className='relative flex h-screen w-full flex-col items-center justify-center gap-12 text-center'>
        <div className='flex h-10 w-10 justify-center'>
          <AppflowyLogo />
        </div>

        <div>
          <span className='text-2xl font-semibold'>{t('signUp.title').replace('@:appName', 'AppFlowy')}</span>
        </div>

        <div className='flex w-full max-w-[340px]  flex-col gap-6'>
          <input
            type='text'
            className={`input w-full ${authError && 'error'}`}
            placeholder={t('signUp.emailHint') ?? ''}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          {/* new user should enter his name, need translation for this field */}
          <input
            type='text'
            className={`input w-full ${authError && 'error'}`}
            placeholder='Name'
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
          />
          <div className='relative w-full'>
            <input
              type={showPassword ? 'text' : 'password'}
              className={`input w-full !pr-10 ${authError && 'error'}`}
              placeholder={t('signUp.passwordHint') ?? ''}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />

            <button
              className='absolute right-0 top-0 flex h-full w-12 items-center justify-center '
              onClick={onTogglePassword}
              type='button'
            >
              <span className='h-6 w-6'>{showPassword ? <EyeClosedSvg /> : <EyeOpenSvg />}</span>
            </button>
          </div>

          <div className='relative w-full'>
            <input
              type={showConfirmPassword ? 'text' : 'password'}
              className={`input w-full !pr-10 ${authError && 'error'}`}
              placeholder={t('signUp.repeatPasswordHint') ?? ''}
              value={repeatedPassword}
              onChange={(e) => setRepeatedPassword(e.target.value)}
            />

            <button
              className='absolute right-0 top-0 flex h-full w-12 items-center justify-center '
              onClick={onToggleConfirmPassword}
              type='button'
            >
              <span className='h-6 w-6'>{showConfirmPassword ? <EyeClosedSvg /> : <EyeOpenSvg />}</span>
            </button>
          </div>
        </div>

        <div className='flex w-full max-w-[340px] flex-col gap-6 '>
          <Button size={'primary'} onClick={() => onSignUpClick()}>
            {t('signUp.getStartedText')}
          </Button>

          {/* signup link */}
          <div className='flex justify-center'>
            <span className='text-xs text-gray-500'>
              {t('signUp.alreadyHaveAnAccount')}
              <Link to={'/auth/login'}>
                <span className='ml-2 text-main-accent hover:text-main-hovered'>{t('signIn.buttonText')}</span>
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
  );
};

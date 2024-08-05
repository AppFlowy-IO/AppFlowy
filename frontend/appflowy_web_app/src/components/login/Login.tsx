import LoginProvider from '@/components/login/LoginProvider';
import MagicLink from '@/components/login/MagicLink';
import { Divider } from '@mui/material';
import React from 'react';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import { useTranslation } from 'react-i18next';

export function Login({ redirectTo }: { redirectTo: string }) {
  const { t } = useTranslation();

  return (
    <div className={'my-10 flex flex-col items-center justify-center gap-[24px] px-4'}>
      <div className={'flex w-full flex-col items-center justify-center gap-[14px]'}>
        <Logo className={'h-10 w-10'} />
        <div className={'text-[24px] font-semibold max-sm:text-[20px]'}>{t('welcomeTo')} AppFlowy</div>
      </div>
      <MagicLink redirectTo={redirectTo} />
      <div className={'flex w-full items-center justify-center gap-2 text-text-caption'}>
        <Divider className={'flex-1 border-line-divider'} />
        {t('web.or')}
        <Divider className={'flex-1 border-line-divider'} />
      </div>
      <LoginProvider redirectTo={redirectTo} />
      <div
        className={
          'mt-[40px] w-[300px] overflow-hidden whitespace-pre-wrap break-words text-center text-[12px] tracking-[0.36px] text-text-caption'
        }
      >
        <span>{t('web.signInAgreement')} </span>
        <a href={'https://appflowy.io/terms'} target={'_blank'} className={'text-fill-default underline'}>
          {t('web.termOfUse')}
        </a>{' '}
        {t('web.and')}{' '}
        <a href={'https://appflowy.io/privacy'} target={'_blank'} className={'text-fill-default underline'}>
          {t('web.privacyPolicy')}
        </a>
        .
      </div>
    </div>
  );
}

export default Login;

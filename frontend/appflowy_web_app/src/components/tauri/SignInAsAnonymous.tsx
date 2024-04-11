import React from 'react';
import { Button } from '@mui/material';
import { useAuth } from '@/components/auth/auth.hooks';
import { useTranslation } from 'react-i18next';

function SignInAsAnonymous () {
  const { signInAsAnonymous } = useAuth();
  const { t } = useTranslation();
  return (
    <>
      <Button
        size={'large'}
        color={'inherit'}
        className={'border-transparent bg-line-divider py-3'}
        variant={'outlined'}
        onClick={signInAsAnonymous}
      >
        {t('signIn.loginStartWithAnonymous')}
      </Button>
      <div className={'flex w-full items-center justify-center gap-2 text-sm'}>
        <div className={'h-px flex-1 bg-line-divider'}/>
        {t('signIn.or')}
        <div className={'h-px flex-1 bg-line-divider'}/>
      </div>
    </>
  );
}

export default SignInAsAnonymous;
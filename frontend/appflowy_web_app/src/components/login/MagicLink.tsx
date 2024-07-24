import { notify } from '@/components/_shared/notify';
import { AFConfigContext } from '@/components/app/AppConfig';
import { Button, CircularProgress, OutlinedInput } from '@mui/material';
import React, { useContext } from 'react';
import { useTranslation } from 'react-i18next';
import validator from 'validator';

function MagicLink({ redirectTo }: { redirectTo: string }) {
  const { t } = useTranslation();
  const [email, setEmail] = React.useState<string>('');
  const [loading, setLoading] = React.useState<boolean>(false);
  const service = useContext(AFConfigContext)?.service;
  const handleSubmit = async () => {
    const isValidEmail = validator.isEmail(email);

    if (!isValidEmail) {
      notify.error(t('signIn.invalidEmail'));
      return;
    }

    setLoading(true);

    try {
      await service?.signInMagicLink({
        email,
        redirectTo,
      });
      notify.success(t('signIn.magicLinkSent'));
    } catch (e) {
      notify.error(t('web.signInError'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={'flex w-full flex-col items-center justify-center gap-[12px]'}>
      <OutlinedInput
        value={email}
        type={'email'}
        className={'h-[46px] w-[380px] rounded-[12px] py-[15px] px-[20px] text-base max-sm:w-full'}
        placeholder={t('signIn.pleaseInputYourEmail')}
        inputProps={{
          className: 'px-0 py-0',
        }}
        onChange={(e) => setEmail(e.target.value)}
      />
      <Button
        onClick={handleSubmit}
        disabled={loading}
        variant={'contained'}
        className={'flex h-[46px] w-[380px] items-center justify-center gap-2 rounded-[12px] text-base max-sm:w-full'}
      >
        {loading ? (
          <>
            <CircularProgress size={'small'} />
            {t('editor.loading')}...
          </>
        ) : (
          t('web.continue')
        )}
      </Button>
    </div>
  );
}

export default MagicLink;

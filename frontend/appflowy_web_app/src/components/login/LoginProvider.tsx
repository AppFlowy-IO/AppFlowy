import { notify } from '@/components/_shared/notify';
import { AFConfigContext } from '@/components/app/AppConfig';
import { Button } from '@mui/material';
import React, { useContext, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as GoogleSvg } from '@/assets/login/google.svg';
import { ReactComponent as GithubSvg } from '@/assets/login/github.svg';
import { ReactComponent as DiscordSvg } from '@/assets/login/discord.svg';

function LoginProvider({ redirectTo }: { redirectTo: string }) {
  const { t } = useTranslation();
  const options = useMemo(
    () => [
      {
        label: t('web.continueWithGoogle'),
        Icon: GoogleSvg,
        value: 'google',
      },
      {
        label: t('web.continueWithGithub'),
        value: 'github',
        Icon: GithubSvg,
      },
      {
        label: t('web.continueWithDiscord'),
        value: 'discord',
        Icon: DiscordSvg,
      },
    ],
    [t]
  );
  const service = useContext(AFConfigContext)?.service;

  const handleClick = async (option: string) => {
    try {
      switch (option) {
        case 'google':
          await service?.signInGoogle({ redirectTo });
          break;
        case 'github':
          await service?.signInGithub({ redirectTo });
          break;
        case 'discord':
          await service?.signInDiscord({ redirectTo });
          break;
      }
    } catch (e) {
      notify.error(t('web.signInError'));
    }
  };

  return (
    <div className={'flex flex-col items-center justify-center gap-[10px]'}>
      {options.map((option) => (
        <Button
          key={option.value}
          color={'inherit'}
          variant={'outlined'}
          onClick={() => handleClick(option.value)}
          className={
            'flex h-[46px] w-[380px] items-center justify-center gap-[10px] rounded-[12px] border border-line-divider text-sm font-medium text-text-title'
          }
        >
          <option.Icon className={'h-[20px] w-[20px]'} />
          {option.label}
        </Button>
      ))}
    </div>
  );
}

export default LoginProvider;

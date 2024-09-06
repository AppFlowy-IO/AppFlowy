import { notify } from '@/components/_shared/notify';
import { AFConfigContext } from '@/components/app/app.hooks';
import { Button, Collapse, Divider } from '@mui/material';
import React, { useCallback, useContext, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as GoogleSvg } from '@/assets/login/google.svg';
import { ReactComponent as GithubSvg } from '@/assets/login/github.svg';
import { ReactComponent as DiscordSvg } from '@/assets/login/discord.svg';
import { ReactComponent as AppleSvg } from '@/assets/login/apple.svg';

function LoginProvider ({ redirectTo }: { redirectTo: string }) {
  const { t } = useTranslation();
  const [expand, setExpand] = React.useState(false);
  const options = useMemo(
    () => [
      {
        label: t('web.continueWithGoogle'),
        Icon: GoogleSvg,
        value: 'google',
      },
      {
        label: t('web.continueWithApple'),
        Icon: AppleSvg,
        value: 'apple',
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
    [t],
  );
  const service = useContext(AFConfigContext)?.service;

  const handleClick = useCallback(async (option: string) => {
    try {
      switch (option) {
        case 'google':
          await service?.signInGoogle({ redirectTo });
          break;
        case 'apple':
          await service?.signInApple({ redirectTo });
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
  }, [service, t, redirectTo]);

  const renderOption = useCallback((option: typeof options[0]) => {

    return <Button
      key={option.value}
      color={'inherit'}
      variant={'outlined'}
      onClick={() => handleClick(option.value)}
      className={
        `flex h-[46px] w-[380px] items-center justify-center gap-[10px] rounded-[12px] border border-line-divider text-sm font-medium  max-sm:w-full text-text-title`
      }
    >
      <option.Icon className={'w-[24px] h-[24px]'} />
      <div className={'w-auto whitespace-pre'}>{option.label}</div>

    </Button>;
  }, [handleClick]);

  return (
    <div className={'flex w-full flex-col items-center justify-center gap-[10px]'}>
      {options.slice(0, 2).map(renderOption)}
      {!expand && <Button
        color={'inherit'}
        size={'small'}
        onClick={() => setExpand(!expand)}
        className={'text-sm w-full flex gap-2 items-center hover:bg-transparent hover:text-text-title font-medium text-text-caption'}
      >
        <Divider className={'flex-1'} />
        {t('web.moreOptions')}
        <Divider className={'flex-1'} />
      </Button>}

      <Collapse in={expand}>
        <div className={'gap-[10px] flex-col flex'}>{options.slice(2).map(renderOption)}</div>
      </Collapse>
    </div>
  );
}

export default LoginProvider;

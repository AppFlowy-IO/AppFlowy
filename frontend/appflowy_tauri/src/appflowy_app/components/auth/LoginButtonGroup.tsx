import Button from '@mui/material/Button';
import GoogleIcon from '$app/assets/settings/google.png';
import GithubIcon from '$app/assets/settings/github.png';
import DiscordIcon from '$app/assets/settings/discord.png';
import { useTranslation } from 'react-i18next';
import { useAuth } from '$app/components/auth/auth.hooks';
import { ProviderTypePB } from '@/services/backend';

export const LoginButtonGroup = () => {
  const { t } = useTranslation();

  const { signIn } = useAuth();

  return (
    <div className={'flex w-full flex-col items-center gap-4'}>
      <Button
        onClick={() => {
          void signIn(ProviderTypePB.Google);
        }}
        className={'w-full rounded-lg border-text-title py-3 text-sm'}
        color={'inherit'}
        variant={'outlined'}
      >
        <img src={GoogleIcon} alt={'Google'} className={'mr-2 h-6 w-6'} />
        {t('button.signInGoogle')}
      </Button>
      <Button
        onClick={() => {
          void signIn(ProviderTypePB.Github);
        }}
        className={'w-full  rounded-lg border-text-title py-3 text-sm'}
        color={'inherit'}
        variant={'outlined'}
      >
        <img src={GithubIcon} alt={'Github'} className={'mr-2 h-6 w-6'} />
        {t('button.signInGithub')}
      </Button>
      <Button
        onClick={() => {
          void signIn(ProviderTypePB.Discord);
        }}
        className={'w-full  rounded-lg border-text-title py-3 text-sm'}
        color={'inherit'}
        variant={'outlined'}
      >
        <img src={DiscordIcon} alt={'Discord'} className={'mr-2 h-6 w-6'} />
        {t('button.signInDiscord')}
      </Button>
    </div>
  );
};

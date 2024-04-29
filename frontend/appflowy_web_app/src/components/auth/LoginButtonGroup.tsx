import Button from '@mui/material/Button';
import GoogleIcon from '@/assets/settings/google.png';
import GithubIcon from '@/assets/settings/github.png';
import DiscordIcon from '@/assets/settings/discord.png';
import { useTranslation } from 'react-i18next';
import { useAuth } from './auth.hooks';
import { ProviderType } from '@/application/user.type';
import { useState } from 'react';
import EmailOutlined from '@mui/icons-material/EmailOutlined';
import SignInWithEmail from './SignInWithEmail';

export const LoginButtonGroup = () => {
  const { t } = useTranslation();
  const [openSignInWithEmail, setOpenSignInWithEmail] = useState(false);
  const { signInWithProvider } = useAuth();

  return (
    <div className={'flex w-full flex-col items-center gap-4'}>
      <Button
        data-cy={'signInWithEmail'}
        onClick={() => {
          setOpenSignInWithEmail(true);
        }}
        className={'w-full rounded-lg border-text-title py-3 text-sm'}
        color={'inherit'}
        variant={'outlined'}
      >
        <EmailOutlined className={'mr-2 h-6 w-6'} />
        {t('signIn.signInWithEmail')}
      </Button>
      <Button
        onClick={() => {
          void signInWithProvider(ProviderType.Google);
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
          void signInWithProvider(ProviderType.Github);
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
          void signInWithProvider(ProviderType.Discord);
        }}
        className={'w-full  rounded-lg border-text-title py-3 text-sm'}
        color={'inherit'}
        variant={'outlined'}
      >
        <img src={DiscordIcon} alt={'Discord'} className={'mr-2 h-6 w-6'} />
        {t('button.signInDiscord')}
      </Button>
      <SignInWithEmail open={openSignInWithEmail} onClose={() => setOpenSignInWithEmail(false)} />
    </div>
  );
};

import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import GoogleIcon from '$app/assets/settings/google.png';
import GithubIcon from '$app/assets/settings/github.png';
import DiscordIcon from '$app/assets/settings/discord.png';

export const Login = ({ onBack }: { onBack: () => void }) => {
  const { t } = useTranslation();

  return (
    <div className={'flex flex-col items-center gap-4'}>
      <Typography variant={'h4'} className={'mb-3 font-medium'}>
        {t('button.login')}
      </Typography>
      <Button className={'w-[70%] rounded-lg border-text-title py-3 text-sm'} color={'inherit'} variant={'outlined'}>
        <img src={GoogleIcon} alt={'Google'} className={'mr-2 h-6 w-6'} />
        {t('button.signInGoogle')}
      </Button>
      <Button className={'w-[70%]  rounded-lg border-text-title py-3 text-sm'} color={'inherit'} variant={'outlined'}>
        <img src={GithubIcon} alt={'Github'} className={'mr-2 h-6 w-6'} />
        {t('button.signInGithub')}
      </Button>
      <Button className={'w-[70%]  rounded-lg border-text-title py-3 text-sm'} color={'inherit'} variant={'outlined'}>
        <img src={DiscordIcon} alt={'Discord'} className={'mr-2 h-6 w-6'} />
        {t('button.signInDiscord')}
      </Button>
      <Button className={'w-[70%] rounded-lg  py-3 text-sm'} onClick={onBack} color={'inherit'} variant={'text'}>
        {t('button.cancel')}
      </Button>
    </div>
  );
};

import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import { downloadPage, openAppFlowySchema, openUrl } from '@/utils/url';
import { Button } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import Popover, { PopoverOrigin } from '@mui/material/Popover';

const popoverOrigin: {
  anchorOrigin: PopoverOrigin;
  transformOrigin: PopoverOrigin;
} = {
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'right',
  },
  transformOrigin: {
    vertical: -10,
    horizontal: 'right',
  },
};

function Header() {
  const { objectId } = useParams();
  const { t } = useTranslation();
  const [anchorEl, setAnchorEl] = React.useState<HTMLButtonElement | null>(null);
  const { icon, name } = usePageInfo(objectId || '');

  return (
    <div className={'appflowy-top-bar flex h-[64px] p-4'}>
      <div className={'flex flex-1 items-center justify-between'}>
        <div className={'flex flex-1 items-center gap-2'}>
          <div>{icon}</div>
          <div className={'flex-1 truncate'}>{name}</div>
        </div>

        <Button
          className={'border-line-border'}
          onClick={(e) => {
            setAnchorEl(e.currentTarget);
          }}
          variant={'outlined'}
          color={'inherit'}
          endIcon={<Logo />}
        >
          Built with
        </Button>
      </div>
      <Popover open={Boolean(anchorEl)} anchorEl={anchorEl} {...popoverOrigin} onClose={() => setAnchorEl(null)}>
        <div className={'flex w-fit flex-col gap-2 p-4'}>
          <Button
            onClick={() => {
              void openUrl(openAppFlowySchema);
            }}
            className={'w-full'}
            variant={'outlined'}
          >
            {`🥳 Open AppFlowy`}
          </Button>
          <div className={'flex w-full items-center justify-center gap-2 text-xs text-text-caption'}>
            <div className={'h-px flex-1 bg-line-divider'} />
            {t('signIn.or')}
            <div className={'h-px flex-1 bg-line-divider'} />
          </div>
          <Button
            onClick={() => {
              void openUrl(downloadPage, '_blank');
            }}
            variant={'contained'}
          >
            {`Download AppFlowy`}
          </Button>
        </div>
      </Popover>
    </div>
  );
}

export default Header;

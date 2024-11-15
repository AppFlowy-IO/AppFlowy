import { Popover } from '@/components/_shared/popover';
import ShareTabs from '@/components/app/share/ShareTabs';
import { Button } from '@mui/material';
import React, { useRef } from 'react';
import { useTranslation } from 'react-i18next';

export function ShareButton ({ viewId }: { viewId: string }) {
  const { t } = useTranslation();

  const [opened, setOpened] = React.useState(false);
  const ref = useRef<HTMLButtonElement>(null);

  return (
    <>
      <Button
        className={'max-sm:hidden'}
        onClick={() => {
          setOpened(true);
        }}
        ref={ref}
        size={'small'}
        variant={'contained'}
        color={'primary'}
      >{t('shareAction.buttonText')}</Button>
      {opened && <Popover
        open={opened}
        anchorEl={ref.current}
        onClose={() => setOpened(false)}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'center',
        }}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'center',
        }}
      >
        <div className={'flex flex-col gap-2 w-fit p-2'}>
          <ShareTabs viewId={viewId} />
        </div>
      </Popover>}
    </>
  );
}

export default ShareButton;
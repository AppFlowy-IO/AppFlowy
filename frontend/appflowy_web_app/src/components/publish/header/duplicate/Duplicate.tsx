import { getPlatform } from '@/utils/platform';
import React, { useCallback, useMemo } from 'react';
import { Button, IconButton, Tooltip } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { LoginModal } from '@/components/login';
import { useSearchParams } from 'react-router-dom';
import { useDuplicate } from '@/components/publish/header/duplicate/useDuplicate';
import DuplicateModal from '@/components/publish/header/duplicate/DuplicateModal';
import { ReactComponent as CopyIcon } from '@/assets/copy.svg';

export function Duplicate () {
  const { t } = useTranslation();
  const { loginOpen, duplicateOpen, handleDuplicateClose, handleLoginClose, url } = useDuplicate();
  const [, setSearch] = useSearchParams();
  const handleClick = useCallback(() => {
    setSearch(prev => {
      prev.set('action', 'duplicate');
      return prev;
    });
  }, [setSearch]);

  const isMobile = useMemo(() => {
    return getPlatform().isMobile;
  }, []);

  return (
    <>
      {isMobile ? (
        <Tooltip title={t('publish.saveThisPage')}>
          <IconButton
            onClick={handleClick}
            size={'small'}
            color={'inherit'}
          >
            <CopyIcon className={'w-5 h-5'} />
          </IconButton>
        </Tooltip>
      ) : <Button
        onClick={handleClick}
        size={'small'}
        variant={'contained'}
        color={'primary'}
      >
        {t('publish.saveThisPage')}
      </Button>}

      <LoginModal
        redirectTo={url}
        open={loginOpen}
        onClose={handleLoginClose}
      />
      <DuplicateModal
        open={duplicateOpen}
        onClose={handleDuplicateClose}
      />
    </>
  );
}

export default Duplicate;

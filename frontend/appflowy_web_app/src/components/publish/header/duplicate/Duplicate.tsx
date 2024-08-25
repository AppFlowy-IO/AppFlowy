import React, { useCallback } from 'react';
import { Button } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { LoginModal } from '@/components/login';
import { useSearchParams } from 'react-router-dom';
import { useDuplicate } from '@/components/publish/header/duplicate/useDuplicate';
import DuplicateModal from '@/components/publish/header/duplicate/DuplicateModal';

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

  return (
    <>
      <Button onClick={handleClick} size={'small'} variant={'outlined'} color={'inherit'}>
        {t('publish.saveThisPage')}
      </Button>
      <LoginModal redirectTo={url} open={loginOpen} onClose={handleLoginClose} />
      {duplicateOpen && <DuplicateModal open={duplicateOpen} onClose={handleDuplicateClose} />}
    </>
  );
}

export default Duplicate;

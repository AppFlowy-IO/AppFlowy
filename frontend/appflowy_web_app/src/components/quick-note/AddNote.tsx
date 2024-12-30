import React from 'react';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { useAddNode } from '@/components/quick-note/QuickNote.hooks';
import { QuickNote } from '@/application/types';
import { Button, CircularProgress } from '@mui/material';
import { useTranslation } from 'react-i18next';

function AddNote ({
  onEnterNote,
  onAdd,
}: {
  onEnterNote: (node: QuickNote) => void;
  onAdd: (note: QuickNote) => void;
}) {
  const {
    handleAdd,
    loading,
  } = useAddNode({
    onEnterNote,
    onAdd,
  });

  const { t } = useTranslation();

  return (
    <>
      <Button
        size={'small'}
        color={'inherit'}
        startIcon={loading ? <CircularProgress size={16} /> : <AddIcon className={'w-4 h-4'} />}
        onClick={handleAdd}
        className={'justify-start w-full'}
      >
        {t('quickNote.addNote')}
      </Button>
    </>
  );
}

export default AddNote;
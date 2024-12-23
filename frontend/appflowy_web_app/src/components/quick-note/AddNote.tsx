import React, { useContext } from 'react';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { useService } from '@/components/main/app.hooks';
import { ToastContext } from '@/components/quick-note/QuickNote.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { QuickNote } from '@/application/types';
import { Button, CircularProgress } from '@mui/material';
import { useTranslation } from 'react-i18next';

function AddNote({
  onEnterNote,
  onAdd,
}: {
  onEnterNote: (node: QuickNote) => void;
  onAdd: (note: QuickNote) => void;
}) {
  const toast = useContext(ToastContext);

  const [loading, setLoading] = React.useState(false);
  const currentWorkspaceId = useCurrentWorkspaceId();
  const service = useService();
  const handleAdd = async () => {
    if (!service || !currentWorkspaceId || loading) return;
    setLoading(true);
    try {
      const note = await service.createQuickNote(currentWorkspaceId, [{
        type: 'paragraph',
        delta: [{ insert: '' }],
        children: [],
      }]);

      onEnterNote(note);
      onAdd(note);
      // eslint-disable-next-line
    } catch (e: any) {
      console.error(e);
      toast.onOpen(e.message);
    } finally {
      setLoading(false);
    }
  };

  const { t } = useTranslation();

  return (
    <>
      <Button
        size={'small'}
        color={'inherit'}
        startIcon={loading ? <CircularProgress className={'w-4 h-4'}/> : <AddIcon className={'w-4 h-4'}/>}
        onClick={handleAdd}
        className={'justify-start w-full'}>
        {t('quickNote.addNote')}
      </Button>
    </>
  );
}

export default AddNote;
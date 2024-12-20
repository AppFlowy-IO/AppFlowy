import React, { useContext } from 'react';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { useService } from '@/components/main/app.hooks';
import { ToastContext } from '@/components/quick-note/QuickNote.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { QuickNote } from '@/application/types';
import { CircularProgress } from '@mui/material';

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

  return (
    <>
      <div
        onClick={handleAdd}
        style={{
          boxShadow: '0px 8px 16px 0px rgba(0, 188, 240, 0.10)',
        }}
        className={'flex select-none relative cursor-pointer text-content-on-fill w-10 h-10 rounded-full items-center justify-center bg-fill-default opacity-90 hover:opacity-100'}>
        {
          loading ? (
            <CircularProgress className={'w-6 h-6'}/>
          ) : <AddIcon className={'w-6 h-6'}/>
        }

      </div>
    </>
  );
}

export default AddNote;
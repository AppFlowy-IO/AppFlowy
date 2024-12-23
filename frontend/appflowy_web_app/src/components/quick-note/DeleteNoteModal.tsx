import React, { useContext } from 'react';
import { ToastContext } from '@/components/quick-note/QuickNote.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { useService } from '@/components/main/app.hooks';
import { NormalModal } from '@/components/_shared/modal';
import { useTranslation } from 'react-i18next';
import { QuickNote } from '@/application/types';
import { getTitle } from '@/components/quick-note/utils';

function DeleteNoteModal({ open, onClose, note, onDelete }: {
  open: boolean;
  onClose: () => void;
  note: QuickNote;
  onDelete: (id: string) => void;
}) {
  const { t } = useTranslation();
  const toast = useContext(ToastContext);

  const [loading, setLoading] = React.useState(false);
  const currentWorkspaceId = useCurrentWorkspaceId();
  const service = useService();
  const handleDelete = async () => {
    if (!service || !currentWorkspaceId || loading) return;
    setLoading(true);
    try {
      await service.deleteQuickNote(currentWorkspaceId, note.id);

      onDelete(note.id);
      onClose();
      // eslint-disable-next-line
    } catch (e: any) {
      console.error(e);
      toast.onOpen(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <NormalModal
      okLoading={loading}
      keepMounted={false}
      disableRestoreFocus={true}
      okText={t('button.delete')}
      cancelText={t('button.cancel')}
      open={open}
      danger={true}
      onClose={onClose}
      title={
        <div
          className={'flex font-semibold items-center w-full text-left'}>
          <span
            className={'truncate w-full'}>{`${t('button.delete')}: ${getTitle(note) || t('menuAppHeader.defaultNewPageName')}`}</span>
        </div>
      }
      onOk={handleDelete}
      PaperProps={{
        className: 'w-[420px] max-w-[70vw]',
      }}>
      <div className={'text-text-caption font-normal'}>
        {t('quickNote.deleteNotePrompt')}
      </div>
    </NormalModal>
  );
}

export default DeleteNoteModal;
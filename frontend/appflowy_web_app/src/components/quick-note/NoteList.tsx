import React, { useCallback, useContext } from 'react';
import { QuickNote as QuickNoteType } from '@/application/types';
import dayjs from 'dayjs';
import { useTranslation } from 'react-i18next';
import { Divider, IconButton, Tooltip } from '@mui/material';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { ToastContext } from '@/components/quick-note/QuickNote.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { useService } from '@/components/main/app.hooks';

function NoteList({
  list,
  onEnterNode,
  onDelete,
  onScroll,
}: {
  list: QuickNoteType[];
  onEnterNode: (node: QuickNoteType) => void;
  onDelete: (id: string) => void;
  onScroll: (e: React.UIEvent<HTMLDivElement>) => void;
}) {
  const { t } = useTranslation();
  const renderTitle = useCallback((last_updated_at: string) => {
    return dayjs(last_updated_at).format('MMMM d, YYYY');
  }, []);

  const renderSummary = useCallback((note: QuickNoteType) => {
    const data = note.data;

    if (!data) return '';
    let text = '';

    for (const block of data) {
      text += block.delta.map((d) => d.insert).join('');
    }

    return text;

  }, []);

  const [hoverId, setHoverId] = React.useState<string | null>(null);

  const toast = useContext(ToastContext);

  const [loading, setLoading] = React.useState(false);
  const currentWorkspaceId = useCurrentWorkspaceId();
  const service = useService();
  const handleDelete = async (id: string) => {
    if (!service || !currentWorkspaceId || loading) return;
    setLoading(true);
    try {
      await service.deleteQuickNote(currentWorkspaceId, id);

      onDelete(id);
      // eslint-disable-next-line
    } catch (e: any) {
      console.error(e);
      toast.onOpen(e.message);
    } finally {
      setLoading(false);
    }
  };

  if (!list || list.length === 0) {
    return <div
      className={'text-center text-sm text-text-caption h-full flex items-center justify-center w-full'}>{t('quickNote.quickNotesEmpty')}</div>;
  }

  return (
    <div onScroll={onScroll} className={'flex flex-col gap-3 h-full appflowy-custom-scroller   overflow-y-auto'}>
      <div className={'flex flex-col'}>
        {
          list.map((note, index) => {
            return (
              <React.StrictMode key={note.id}>
                <div
                  onClick={() => onEnterNode(note)}
                  onMouseEnter={() => setHoverId(note.id)}
                  onMouseLeave={() => setHoverId(null)}
                  key={note.id}
                  className={`px-5 relative hover:bg-fill-list-hover text-sm overflow-hidden cursor-pointer`}
                >
                  <div
                    className={`w-full 
                    ${index === list.length - 1 ? '' : 'border-b'} py-4 flex justify-center min-h-[68px] flex-col border-line-card`}>
                    <div className={'font-medium'}>
                      {renderTitle(note.last_updated_at)}
                    </div>
                    <div className={'font-normal w-full truncate text-text-caption'}>
                      {renderSummary(note)}
                    </div>
                  </div>
                  {hoverId === note.id ? <div
                    className={'absolute border-line-divider right-4 top-1/2 bg-bg-body border rounded-[8px] p-1 -translate-y-1/2 flex items-center gap-1.5'}>
                    <Tooltip title={t('button.edit')}>
                      <IconButton onClick={(e) => {
                        e.stopPropagation();
                        onEnterNode(note);
                      }} size={'small'}>
                        <EditIcon/>
                      </IconButton>
                    </Tooltip>
                    <Divider orientation={'vertical'} flexItem className={'my-1'}/>
                    <Tooltip title={t('button.delete')}>
                      <IconButton disabled={loading} onClick={(e) => {
                        e.stopPropagation();

                        void handleDelete(note.id);
                      }} size={'small'}>
                        <DeleteIcon/>
                      </IconButton>
                    </Tooltip>
                  </div> : null}
                </div>

              </React.StrictMode>
            );
          })
        }
      </div>
    </div>
  );
}

export default NoteList;
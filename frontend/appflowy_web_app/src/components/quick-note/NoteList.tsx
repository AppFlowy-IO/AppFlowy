import React, { useCallback } from 'react';
import { QuickNote, QuickNote as QuickNoteType } from '@/application/types';
import { useTranslation } from 'react-i18next';
import { Divider, IconButton, Tooltip } from '@mui/material';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import DeleteNoteModal from '@/components/quick-note/DeleteNoteModal';
import { getSummary, getTitle, getUpdateTime } from '@/components/quick-note/utils';

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
  const renderTitle = useCallback((note: QuickNote) => {
    return getTitle(note) || t('menuAppHeader.defaultNewPageName');
  }, [t]);

  const [openDeleteModal, setOpenDeleteModal] = React.useState(false);
  const [selectedNote, setSelectedNote] = React.useState<QuickNoteType | null>(null);
  const [hoverId, setHoverId] = React.useState<string | null>(null);

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
                    ${index === list.length - 1 ? '' : 'border-b'} py-4 gap-1 flex justify-center min-h-[68px] flex-col border-line-card`}>
                    <div className={'font-medium w-full truncate'}>
                      {renderTitle(note)}
                    </div>
                    <div className={'font-normal w-full flex gap-2'}>
                      <span className={'text-text-title'}>
                        {getUpdateTime(note)}
                      </span>
                      <span className={'flex-1 truncate text-text-caption'}>{getSummary(note)}</span>

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
                      <IconButton onClick={(e) => {
                        e.stopPropagation();

                        setSelectedNote(note);
                        setOpenDeleteModal(true);
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
      {selectedNote && <DeleteNoteModal
        onDelete={onDelete}
        open={openDeleteModal}
        onClose={() => {
          setOpenDeleteModal(false);
          setSelectedNote(null);
        }}
        note={selectedNote}/>
      }

    </div>
  );
}

export default NoteList;
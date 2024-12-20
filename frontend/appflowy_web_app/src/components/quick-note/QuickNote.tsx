import React, { Suspense, useCallback, useEffect, useMemo, useRef } from 'react';
import { IconButton, Tooltip, Slide, Snackbar, Portal } from '@mui/material';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';
import { useTranslation } from 'react-i18next';
import { createHotkey, createHotKeyLabel, HOT_KEY_NAME } from '@/utils/hotkeys';
import Popover from '@mui/material/Popover';
import NoteHeader from '@/components/quick-note/NoteHeader';
import NoteListHeader from '@/components/quick-note/NoteListHeader';
import { TransitionProps } from '@mui/material/transitions';
import AddNote from '@/components/quick-note/AddNote';
import { LISI_LIMIT, ToastContext } from './QuickNote.hooks';
import { useService } from '@/components/main/app.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { QuickNote as QuickNoteType, QuickNoteEditorData } from '@/application/types';
import NoteList from '@/components/quick-note/NoteList';

const Note = React.lazy(() => import('@/components/quick-note/Note'));

const PAPER_SIZE = [480, 316];
const Transition = React.forwardRef(function Transition(
  props: TransitionProps & {
    children: React.ReactElement;
  },
  ref: React.Ref<unknown>,
) {
  return <Slide
    direction="up"
    ref={ref}
    {...props}
  />;
});

enum QuickNoteRoute {
  NOTE = 'note',
  LIST = 'list',
}

export function QuickNote() {
  const { t } = useTranslation();
  const modifier = useMemo(() => createHotKeyLabel(HOT_KEY_NAME.QUICK_NOTE), []);
  const [open, setOpen] = React.useState(false);
  const [position, setPosition] = React.useState<{ x: number, y: number } | undefined>(undefined);
  const [isDragging, setIsDragging] = React.useState(false);
  const dragStartPos = useRef({ x: 0, y: 0 });
  const [route, setRoute] = React.useState<QuickNoteRoute>(QuickNoteRoute.LIST);
  const [pageSize, setPageSize] = React.useState(PAPER_SIZE);
  const [expand, setExpand] = React.useState(false);
  const paper = React.useRef<HTMLDivElement>(null);
  const [toastMessage, setToastMessage] = React.useState('');
  const [openToast, setOpenToast] = React.useState(false);

  const [currentNote, setCurrentNote] = React.useState<QuickNoteType | undefined>(undefined);
  const [noteList, setNoteList] = React.useState<QuickNoteType[]>([]);
  const hasMoreRef = React.useRef(true);
  const listParamsRef = useRef({
    offset: 0,
    limit: LISI_LIMIT,
    searchTerm: '',
  });

  const service = useService();
  const currentWorkspaceId = useCurrentWorkspaceId();

  const handleOpenToast = useCallback((msg: string) => {
    setOpenToast(true);
    setToastMessage(msg);
  }, []);

  const loadNoteList = useCallback(async (newParams: {
    offset: number;
    limit: number;
    searchTerm: string;
  }) => {
    if (!service || !currentWorkspaceId) return;
    try {
      const notes = await service.getQuickNoteList(currentWorkspaceId, newParams);

      return notes;
      // eslint-disable-next-line
    } catch (e: any) {
      console.error(e);
      handleOpenToast(e.message);
    }
  }, [service, currentWorkspaceId, handleOpenToast]);

  const initNoteList = useCallback(async () => {
    const params = {
      offset: 0,
      limit: LISI_LIMIT,
      searchTerm: '',
    };
    const notes = await loadNoteList(params);

    if (notes) {
      setNoteList(notes.data);
      hasMoreRef.current = notes.has_more;
    }
  }, [loadNoteList]);

  useEffect(() => {
    if (!open) return;
    void initNoteList();
  }, [initNoteList, open]);

  const handleEnterNote = useCallback((note: QuickNoteType) => {
    setCurrentNote(note);
    setRoute(QuickNoteRoute.NOTE);
  }, []);

  const handleLoadMore = useCallback(async () => {
    const params = {
      ...listParamsRef.current,
      offset: noteList.length,
    };
    const notes = await loadNoteList(params);

    if (notes) {
      setNoteList(prev => [...prev, ...notes.data]);
      hasMoreRef.current = notes.has_more;
    }
  }, [loadNoteList, noteList]);

  const handleSearch = useCallback(async (searchTerm: string) => {
    const newParams = {
      limit: LISI_LIMIT,
      offset: 0,
      searchTerm,
    };

    listParamsRef.current = newParams;

    const notes = await loadNoteList(newParams);

    if (notes) {
      setNoteList(notes.data);
      hasMoreRef.current = notes.has_more;
    }
  }, [loadNoteList]);

  const handleClose = () => {
    setOpen(false);
  };

  const resetPosition = useCallback(() => {
    const main = document.querySelector('.appflowy-layout');

    if (!main) return;

    if (expand) {
      setPageSize([window.innerWidth * 0.8, window.innerHeight * 0.8]);
      // center
      setPosition({
        x: window.innerWidth * 0.1,
        y: window.innerHeight * 0.1,
      });

    } else {
      setPageSize(PAPER_SIZE);
      const rect = main.getBoundingClientRect();

      setPosition({ y: rect.bottom - PAPER_SIZE[1] - 16, x: rect.left + 16 });
    }
  }, [expand]);

  useEffect(() => {
    resetPosition();
  }, [resetPosition]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (createHotkey(HOT_KEY_NAME.QUICK_NOTE)(e)) {
        e.stopPropagation();
        e.preventDefault();
        setOpen(prev => {
          if (!prev) {
            setRoute(QuickNoteRoute.NOTE);
          }

          return !prev;
        });
      }
    };

    document.addEventListener('keydown', handleKeyDown);

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, []);

  const handleMouseDown = (event: React.MouseEvent) => {
    if (!position) return;
    setIsDragging(true);
    dragStartPos.current = {
      x: event.clientX - position.x,
      y: event.clientY - position.y,
    };
  };

  useEffect(() => {
    const handleMouseMove = (event: MouseEvent) => {
      if (isDragging) {
        setPosition({
          x: event.clientX - dragStartPos.current.x,
          y: event.clientY - dragStartPos.current.y,
        });
      }
    };

    const handleMouseUp = () => {
      setIsDragging(false);
    };

    const handleKeyDown = (e: KeyboardEvent) => {
      if (createHotkey(HOT_KEY_NAME.ESCAPE)(e)) {
        handleClose();
      }
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    document.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
      document.removeEventListener('keydown', handleKeyDown);

    };
  }, [isDragging]);

  const handleUpdateNodeData = useCallback((id: string, data: QuickNoteEditorData[]) => {
    setNoteList(prev => {
      return prev.map(note => {
        if (note.id === id) {
          return {
            ...note,
            data,
          };
        }

        return note;
      });
    });
  }, []);

  const renderHeader = () => {
    if (route === QuickNoteRoute.NOTE && currentNote) {
      return (
        <NoteHeader
          note={currentNote}
          expand={expand}
          onToggleExpand={() => {
            setExpand(prev => !prev);
          }}
          onClose={handleClose}
          onBack={() => {
            setRoute(QuickNoteRoute.LIST);
          }}/>
      );
    }

    return <NoteListHeader
      onSearch={handleSearch}
      onClose={handleClose}
      expand={expand}
      onToggleExpand={() => {
        setExpand(prev => !prev);
      }}
    />;
  };

  const handleScrollList = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    const target = e.target as HTMLDivElement;

    const hasMore = hasMoreRef.current;

    if (!hasMore) return;

    if (target.scrollHeight - target.scrollTop === target.clientHeight && hasMoreRef.current) {
      void handleLoadMore();
    }
  }, [handleLoadMore]);

  return (
    <>
      <Tooltip title={
        <>
          <div>{t('quickNote.label')}</div>
          <div className={'text-xs text-text-caption'}>{modifier}</div>
        </>
      }>
        <IconButton
          size={'small'}
          onClick={(e) => {
            if (open) {
              handleClose();
              return;
            }
            
            setOpen(true);
            const rect = e.currentTarget.getBoundingClientRect();

            setPosition(prev => !prev ? { x: rect.right + 60, y: rect.bottom - PAPER_SIZE[1] } : prev);
          }}
        >
          <EditIcon/>
        </IconButton>
      </Tooltip>
      <Popover
        disableAutoFocus={true}
        disableEnforceFocus={true}
        disableRestoreFocus={true}
        TransitionComponent={Transition}
        slotProps={{
          root: {
            style: {
              pointerEvents: 'none',
            },
          },
          paper: {
            style: {
              userSelect: 'none',
              pointerEvents: 'auto',
              width: pageSize[0],
              height: pageSize[1],
            },
            ref: paper,
            className: 'flex flex-col relative',
          },
        }}
        open={open && Boolean(position)}
        anchorReference={'anchorPosition'}
        anchorPosition={position ? {
          top: position.y,
          left: position.x,
        } : undefined}
        onClose={handleClose}
      >
        <ToastContext.Provider value={{
          onOpen: handleOpenToast,
          onClose: () => {
            setToastMessage('');
            setOpenToast(false);
          },
          open: openToast,
        }}>
          <div onMouseDown={handleMouseDown} style={{
            cursor: isDragging ? 'grabbing' : 'grab',
          }}
               className={'bg-note-header py-2 px-5 flex items-center justify-between gap-5 h-[44px] w-full'}>
            <div className={'flex-1'}>{renderHeader()}</div>
          </div>
          <div
            className={'flex-1 flex-col overflow-hidden relative flex'}
          >
            {
              route === QuickNoteRoute.NOTE && currentNote ?
                <>
                  <Suspense>
                    <Note note={currentNote} onUpdateData={(data) => {
                      handleUpdateNodeData(currentNote.id, data);
                    }}/>
                  </Suspense>
                </> : <NoteList
                  onScroll={handleScrollList}
                  onEnterNode={handleEnterNote}
                  list={noteList}
                  onDelete={(id) => {
                    setNoteList(prev => prev.filter(note => note.id !== id));
                  }}
                />
            }
          </div>
          <div className={'absolute right-4 bottom-7'}>
            <AddNote onAdd={(note) => {
              setNoteList(prev => [note, ...prev]);
            }} onEnterNote={handleEnterNote}/>
          </div>

          <Portal container={paper.current}>
            <Snackbar
              style={{
                position: 'absolute',
                bottom: 100,
              }}
              ContentProps={{
                style: {
                  padding: 0,
                  paddingLeft: 16,
                  paddingRight: 16,
                  borderRadius: 8,
                },
              }}
              open={openToast}
              autoHideDuration={3000}
              onClose={() => setOpenToast(false)}
              message={toastMessage}
              anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
            />
          </Portal>
        </ToastContext.Provider>
      </Popover>
    </>
  );
}

export default QuickNote;
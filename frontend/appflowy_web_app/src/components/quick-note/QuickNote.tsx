import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { IconButton, Tooltip, Zoom, Snackbar, Portal } from '@mui/material';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';
import { useTranslation } from 'react-i18next';
import { createHotkey, createHotKeyLabel, HOT_KEY_NAME } from '@/utils/hotkeys';
import Popover from '@mui/material/Popover';
import NoteHeader from '@/components/quick-note/NoteHeader';
import NoteListHeader from '@/components/quick-note/NoteListHeader';
import { TransitionProps } from '@mui/material/transitions';
import { LISI_LIMIT, ToastContext } from './QuickNote.hooks';
import { useService } from '@/components/main/app.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { QuickNote as QuickNoteType, QuickNoteEditorData } from '@/application/types';
import NoteList from '@/components/quick-note/NoteList';
import { getPopoverPosition, setPopoverPosition } from '@/components/quick-note/utils';
import Note from '@/components/quick-note/Note';

const PAPER_SIZE = [480, 396];
const Transition = React.forwardRef(function Transition(
  props: TransitionProps & {
    children: React.ReactElement;
  },
  ref: React.Ref<unknown>,
) {
  return <Zoom
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
  const pageSizeRef = useRef(PAPER_SIZE);
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

  const handleEnterNote = useCallback((note: QuickNoteType) => {
    setCurrentNote(note);
    setRoute(QuickNoteRoute.NOTE);
  }, []);

  const handleAdd = useCallback(async () => {
    if (!service || !currentWorkspaceId) return;
    try {
      const note = await service.createQuickNote(currentWorkspaceId, [{
        type: 'paragraph',
        delta: [{ insert: '' }],
        children: [],
      }]);

      setNoteList(prev => [note, ...prev]);

      handleEnterNote(note);
      // eslint-disable-next-line
    } catch (e: any) {
      console.error(e);
      handleOpenToast(e.message);
    }
  }, [service, currentWorkspaceId, handleEnterNote, handleOpenToast]);

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

    return notes;
  }, [loadNoteList]);

  useEffect(() => {
    setOpen(false);
    setRoute(QuickNoteRoute.LIST);
    setCurrentNote(undefined);
  }, [currentWorkspaceId]);

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

    const localPosition = getPopoverPosition()[expand ? 'expand' : 'normal'];

    if (expand) {
      pageSizeRef.current = [Math.min(window.innerWidth * 0.8, 840), Math.min(window.innerHeight * 0.9, 760)];

      if (localPosition) {
        setPosition(localPosition);
      } else {
        // center
        setPosition({
          x: window.innerWidth / 2,
          y: window.innerHeight / 2,
        });
      }

    } else {
      pageSizeRef.current = PAPER_SIZE;
      const rect = main.getBoundingClientRect();

      if (localPosition) {
        setPosition(localPosition);
        return;
      }

      setPosition({ y: rect.bottom - PAPER_SIZE[1] / 2, x: rect.left + PAPER_SIZE[0] / 2 + 16 });
    }
  }, [expand]);

  useEffect(() => {
    resetPosition();
  }, [resetPosition]);

  const buttonRef = useRef<HTMLButtonElement>(null);
  const handleOpen = useCallback(async (forceCreate?: boolean) => {

    const el = buttonRef.current;

    if (!el) return;
    const rect = el.getBoundingClientRect();

    const localPosition = getPopoverPosition()[expand ? 'expand' : 'normal'];

    if (localPosition) {
      setPosition(localPosition);
    } else {
      setPosition(prev => !prev ? {
        x: rect.right + PAPER_SIZE[0] / 2,
        y: rect.bottom - PAPER_SIZE[1] / 2,
      } : prev);
    }

    await initNoteList();

    if (route === QuickNoteRoute.LIST || forceCreate) {
      await handleAdd();
    }

    setOpen(true);
  }, [expand, initNoteList, route, handleAdd]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (createHotkey(HOT_KEY_NAME.QUICK_NOTE)(e)) {
        e.stopPropagation();
        e.preventDefault();

        void (async () => {
          try {
            await handleOpen(true);
            // eslint-disable-next-line
          } catch (e: any) {
            console.error(e);
            handleOpenToast(e.message);
          }
        })();
      } else if (createHotkey(HOT_KEY_NAME.ESCAPE)(e)) {
        handleClose();
      }
    };

    document.addEventListener('keydown', handleKeyDown);

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleOpen, handleOpenToast]);

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

        const x = event.clientX - dragStartPos.current.x;
        const y = event.clientY - dragStartPos.current.y;

        const newPos = {
          x: Math.min(
            Math.max(x, pageSizeRef.current[0] / 2),
            window.innerWidth - pageSizeRef.current[0] / 2,
          ),
          y: Math.min(
            Math.max(y, pageSizeRef.current[1] / 2),
            window.innerHeight - pageSizeRef.current[1] / 2,
          ),
        };

        setPosition(newPos);
        const localPosition = getPopoverPosition();

        setPopoverPosition({
          ...localPosition,
          [expand ? 'expand' : 'normal']: newPos,
        });
      }
    };

    const handleMouseUp = () => {
      setIsDragging(false);
    };

    document.addEventListener('mousemove', handleMouseMove, true);
    document.addEventListener('mouseup', handleMouseUp);
    return () => {
      document.removeEventListener('mousemove', handleMouseMove, true);
      document.removeEventListener('mouseup', handleMouseUp);

    };
  }, [isDragging, expand]);

  const handleUpdateNodeData = useCallback((id: string, data: QuickNoteEditorData[]) => {
    setNoteList(prev => {
      return prev.map(note => {
        if (note.id === id) {
          return {
            ...note,
            data,
            last_updated_at: new Date().toISOString(),
          };
        }

        return note;
      }).sort((a, b) => {
        return new Date(b.last_updated_at).getTime() - new Date(a.last_updated_at).getTime();
      });
    });
    if (id === currentNote?.id) {
      setCurrentNote(prev => {
        if (prev) {
          return {
            ...prev,
            data,
            last_updated_at: new Date().toISOString(),
          };
        }

        return prev;
      });
    }
  }, [currentNote?.id]);

  const handleToggleExpand = useCallback(() => {
    setOpen(false);
    setTimeout(() => {
      setOpen(true);
      setExpand(prev => !prev);
    }, 200);

  }, []);

  const handleDeleteNotes = useCallback((notes: QuickNoteType[]) => {
    if (!service || !currentWorkspaceId) return;
    notes.forEach(note => {
      void (async () => {
        try {
          await service.deleteQuickNote?.(currentWorkspaceId, note.id);
          setNoteList(prev => prev.filter(n => n.id !== note.id));
          // eslint-disable-next-line
        } catch (e: any) {
          console.error(e);
          handleOpenToast(e.message);
        }
      })();
    });
  }, [currentWorkspaceId, handleOpenToast, service]);

  const clearEmptyNotes = useCallback(() => {

    if (!currentNote) return;

    if (currentNote.last_updated_at === currentNote.created_at) {
      handleDeleteNotes([currentNote]);
    }

  }, [handleDeleteNotes, currentNote]);

  const handleBackList = useCallback(() => {
    const search = listParamsRef.current.searchTerm;

    if (search) {
      listParamsRef.current = {
        offset: 0,
        limit: LISI_LIMIT,
        searchTerm: '',
      };
      void handleSearch('');
    }

    setRoute(QuickNoteRoute.LIST);
    clearEmptyNotes();
  }, [handleSearch, clearEmptyNotes]);

  const renderHeader = () => {
    if (route === QuickNoteRoute.NOTE && currentNote) {
      return (
        <NoteHeader
          note={currentNote}
          expand={expand}
          onToggleExpand={handleToggleExpand}
          onClose={handleClose}
          onBack={handleBackList}/>
      );
    }

    return <NoteListHeader
      onSearch={handleSearch}
      onClose={handleClose}
      expand={expand}
      onToggleExpand={handleToggleExpand}
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

  const handleAddedNote = useCallback((note: QuickNoteType) => {
    setNoteList(prev => [note, ...prev]);
  }, []);

  return (
    <>
      <Tooltip title={
        <>
          <div>{t('quickNote.label')}</div>
          <div className={'text-xs text-text-caption'}>{modifier}</div>
        </>
      }>
        <IconButton
          ref={buttonRef}
          size={'small'}
          onClick={e => {
            e.currentTarget.blur();
            if (open) {
              handleClose();
              return;
            }

            void handleOpen();
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
              width: pageSizeRef.current[0],
              height: pageSizeRef.current[1],
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
        transformOrigin={{
          vertical: 'center',
          horizontal: 'center',
        }}
        onClose={handleClose}
        keepMounted={true}
      >
        <ToastContext.Provider value={{
          onOpen: handleOpenToast,
          onClose: () => {
            setToastMessage('');
            setOpenToast(false);
          },
          open: openToast,
        }}>
          <div
            onMouseDown={handleMouseDown}
            style={{
              cursor: isDragging ? 'grabbing' : 'grab',
            }}

            className={'bg-note-header py-2 px-5 flex items-center justify-between gap-5 h-[44px] w-full'}>
            <div className={'flex-1 overflow-hidden w-full'}>{renderHeader()}</div>
          </div>
          <div
            className={'flex-1 flex-col overflow-hidden relative flex'}
          >
            {
              route === QuickNoteRoute.NOTE && currentNote ?
                <>
                  <Note
                    onAdd={handleAddedNote}
                    onEnterNote={handleEnterNote} note={currentNote}
                    onUpdateData={(data) => {
                      handleUpdateNodeData(currentNote.id, data);
                    }}/>
                </> : <NoteList
                  onAdd={handleAddedNote}
                  onScroll={handleScrollList}
                  onEnterNode={handleEnterNote}
                  list={noteList}
                  onDelete={(id) => {
                    setNoteList(prev => prev.filter(note => note.id !== id));
                  }}
                />
            }
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
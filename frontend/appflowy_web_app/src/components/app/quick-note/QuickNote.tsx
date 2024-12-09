import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { IconButton, Tooltip, Slide } from '@mui/material';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';
import { useTranslation } from 'react-i18next';
import { createHotkey, createHotKeyLabel, HOT_KEY_NAME } from '@/utils/hotkeys';
import Popover from '@mui/material/Popover';
import NoteHeader from '@/components/app/quick-note/NoteHeader';
import NoteListHeader from '@/components/app/quick-note/NoteListHeader';
import { TransitionProps } from '@mui/material/transitions';

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
  const [route, setRoute] = React.useState<QuickNoteRoute>(QuickNoteRoute.NOTE);
  const [pageSize, setPageSize] = React.useState(PAPER_SIZE);
  const [expand, setExpand] = React.useState(false);

  const handleClose = () => {
    setOpen(false);
    dragStartPos.current = { x: 0, y: 0 };
    setPosition(undefined);
    setExpand(false);
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
    if (open) {
      resetPosition();
    }
  }, [open, resetPosition]);

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

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging]);

  const renderHeader = () => {
    if (route === QuickNoteRoute.NOTE) {
      return (
        <NoteHeader
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
      onClose={handleClose}
      onEnterNote={() => {
        setRoute(QuickNoteRoute.NOTE);
      }}/>;
  };

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
          onClick={() => {
            setRoute(QuickNoteRoute.NOTE);
            setOpen(true);
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
            className: 'flex flex-col',
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
        <div onMouseDown={handleMouseDown} style={{
          cursor: isDragging ? 'grabbing' : 'grab',
        }} className={'bg-note-header py-2 px-5 flex items-center justify-between gap-5 h-[44px] w-full'}>
          <div className={'flex-1'}>{renderHeader()}</div>
        </div>
      </Popover>
    </>
  );
}

export default QuickNote;
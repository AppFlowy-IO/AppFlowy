import { ViewLayout } from '@/application/types';
import React, { useMemo } from 'react';
import { ReactComponent as BoardSvg } from '@/assets/board.svg';
import { ReactComponent as CalendarSvg } from '@/assets/calendar.svg';
import { ReactComponent as DocumentSvg } from '@/assets/document.svg';
import { ReactComponent as GridSvg } from '@/assets/grid.svg';
import { ReactComponent as ChatSvg } from '@/assets/chat_ai.svg';

export function ViewIcon ({ layout, size }: {
  layout: ViewLayout;
  size: number | 'small' | 'medium' | 'large' | 'unset'
}) {
  const iconSize = useMemo(() => {
    if (size === 'small') {
      return 'h-4 w-4';
    }

    if (size === 'medium') {
      return 'h-4.5 w-4.5';
    }

    if (size === 'large') {
      return 'h-8 w-8';
    }

    if (size === 'unset') {
      return '';
    }

    return `h-${size} w-${size}`;
  }, [size]);

  switch (layout) {
    case ViewLayout.AIChat:
      return <ChatSvg className={iconSize} />;
    case ViewLayout.Grid:
      return <GridSvg className={iconSize} />;
    case ViewLayout.Board:
      return <BoardSvg className={iconSize} />;
    case ViewLayout.Calendar:
      return <CalendarSvg className={iconSize} />;
    case ViewLayout.Document:
      return <DocumentSvg className={iconSize} />;
    default:
      return null;
  }

}

export default ViewIcon;

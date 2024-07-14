import { ViewLayout } from '@/application/collab.type';
import React, { useMemo } from 'react';
import { ReactComponent as BoardSvg } from '@/assets/board.svg';
import { ReactComponent as CalendarSvg } from '@/assets/calendar.svg';
import { ReactComponent as DocumentSvg } from '@/assets/document.svg';
import { ReactComponent as GridSvg } from '@/assets/grid.svg';

export function ViewIcon({ layout, size }: { layout: ViewLayout; size: number | 'small' | 'medium' | 'large' }) {
  const iconSize = useMemo(() => {
    if (size === 'small') {
      return 'h-4 w-4';
    }

    if (size === 'medium') {
      return 'h-6 w-6';
    }

    if (size === 'large') {
      return 'h-8 w-8';
    }

    return `h-${size} w-${size}`;
  }, [size]);

  if (layout === ViewLayout.Grid) {
    return <GridSvg className={iconSize} />;
  }

  if (layout === ViewLayout.Board) {
    return <BoardSvg className={iconSize} />;
  }

  if (layout === ViewLayout.Calendar) {
    return <CalendarSvg className={iconSize} />;
  }

  if (layout === ViewLayout.Document) {
    return <DocumentSvg className={iconSize} />;
  }

  return null;
}

export default ViewIcon;

import { ViewLayoutPB } from '@/services/backend';
import React from 'react';
import { Page } from '$app_reducers/pages/slice';
import { ReactComponent as DocumentIcon } from '$app/assets/document.svg';
import { ReactComponent as GridIcon } from '$app/assets/grid.svg';
import { ReactComponent as BoardIcon } from '$app/assets/board.svg';
import { ReactComponent as CalendarIcon } from '$app/assets/date.svg';

export function getPageIcon(page: Page) {
  if (page.icon) {
    return page.icon.value;
  }

  switch (page.layout) {
    case ViewLayoutPB.Document:
      return <DocumentIcon className={'h-4 w-4'} />;
    case ViewLayoutPB.Grid:
      return <GridIcon className={'h-4 w-4'} />;
    case ViewLayoutPB.Board:
      return <BoardIcon className={'h-4 w-4'} />;
    case ViewLayoutPB.Calendar:
      return <CalendarIcon className={'h-4 w-4'} />;
    default:
      return null;
  }
}

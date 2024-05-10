import { ViewLayout, YjsFolderKey, YView } from '@/application/collab.type';
import { useViewSelector } from '@/application/folder-yjs';
import React, { useMemo } from 'react';
import { ReactComponent as DocumentSvg } from '@/assets/document.svg';
import { ReactComponent as GridSvg } from '@/assets/grid.svg';
import { ReactComponent as BoardSvg } from '@/assets/board.svg';
import { ReactComponent as CalendarSvg } from '@/assets/date.svg';
import { useTranslation } from 'react-i18next';

export function usePageInfo(id: string) {
  const { view } = useViewSelector(id);

  const layout = view?.get(YjsFolderKey.layout);
  const icon = view?.get(YjsFolderKey.icon);
  const name = view?.get(YjsFolderKey.name) || '';
  const iconObj = useMemo(() => {
    try {
      return JSON.parse(icon || '');
    } catch (e) {
      return null;
    }
  }, [icon]);
  const defaultIcon = useMemo(() => {
    switch (parseInt(layout ?? '0')) {
      case ViewLayout.Document:
        return <DocumentSvg />;
      case ViewLayout.Grid:
        return <GridSvg />;
      case ViewLayout.Board:
        return <BoardSvg />;
      case ViewLayout.Calendar:
        return <CalendarSvg />;
      default:
        return <DocumentSvg />;
    }
  }, [layout]);

  const { t } = useTranslation();

  return {
    icon: iconObj?.value || defaultIcon,
    name: name || t('menuAppHeader.defaultNewPageName'),
    view: view as YView,
  };
}

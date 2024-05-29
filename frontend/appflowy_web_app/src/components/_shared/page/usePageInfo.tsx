import { FontLayout, LineHeightLayout, ViewLayout, YjsFolderKey, YView } from '@/application/collab.type';
import { useViewSelector } from '@/application/folder-yjs';
import { CoverType } from '@/application/folder-yjs/folder.type';
import React, { useEffect, useMemo, useState } from 'react';
import { ReactComponent as DocumentSvg } from '$icons/16x/document.svg';
import { ReactComponent as GridSvg } from '$icons/16x/grid.svg';
import { ReactComponent as BoardSvg } from '$icons/16x/board.svg';
import { ReactComponent as CalendarSvg } from '$icons/16x/date.svg';
import { useTranslation } from 'react-i18next';

export interface PageCover {
  type: CoverType;
  value: string;
}

export interface PageExtra {
  cover: PageCover | null;
  fontLayout: FontLayout;
  lineHeightLayout: LineHeightLayout;
  font?: string;
}

function parseExtra(extra: string): PageExtra {
  let extraObj;

  try {
    extraObj = JSON.parse(extra);
  } catch (e) {
    extraObj = {};
  }

  return {
    cover: extraObj.cover
      ? {
          type: extraObj.cover.type,
          value: extraObj.cover.value,
        }
      : null,
    fontLayout: extraObj.font_layout || FontLayout.normal,
    lineHeightLayout: extraObj.line_height_layout || LineHeightLayout.normal,
    font: extraObj.font,
  };
}

export function usePageInfo(id: string) {
  const { view } = useViewSelector(id);

  const [loading, setLoading] = useState(true);
  const layout = view?.get(YjsFolderKey.layout);
  const icon = view?.get(YjsFolderKey.icon);
  const extra = view?.get(YjsFolderKey.extra);
  const name = view?.get(YjsFolderKey.name) || '';
  const iconObj = useMemo(() => {
    try {
      return JSON.parse(icon || '');
    } catch (e) {
      return null;
    }
  }, [icon]);

  const extraObj = useMemo(() => {
    return parseExtra(extra || '');
  }, [extra]);

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

  useEffect(() => {
    setLoading(!view);
  }, [view]);
  return {
    icon: iconObj?.value || defaultIcon,
    name: name || t('menuAppHeader.defaultNewPageName'),
    view: view as YView,
    loading,
    extra: extraObj,
  };
}

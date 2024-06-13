import { ViewLayout } from '@/application/collab.type';
import { Crumb, useNavigateToView } from '@/application/folder-yjs';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DocumentSvg } from '$icons/16x/document.svg';
import { ReactComponent as GridSvg } from '$icons/16x/grid.svg';
import { ReactComponent as BoardSvg } from '$icons/16x/board.svg';
import { ReactComponent as CalendarSvg } from '$icons/16x/date.svg';

const renderCrumbIcon = (icon: string) => {
  if (Number(icon) === ViewLayout.Grid) {
    return <GridSvg className={'h-4 w-4'} />;
  }

  if (Number(icon) === ViewLayout.Board) {
    return <BoardSvg className={'h-4 w-4'} />;
  }

  if (Number(icon) === ViewLayout.Calendar) {
    return <CalendarSvg className={'h-4 w-4'} />;
  }

  if (Number(icon) === ViewLayout.Document) {
    return <DocumentSvg className={'h-4 w-4'} />;
  }

  return icon;
};

function Item({ crumb, disableClick = false }: { crumb: Crumb; disableClick?: boolean }) {
  const { viewId, icon, name } = crumb;

  const { t } = useTranslation();
  const onNavigateToView = useNavigateToView();

  return (
    <div
      className={`flex items-center gap-1 ${!disableClick ? 'cursor-pointer' : 'flex-1 overflow-hidden'}`}
      onClick={() => {
        if (disableClick) return;
        onNavigateToView?.(viewId);
      }}
    >
      {renderCrumbIcon(icon)}
      <span
        className={!disableClick ? 'max-w-[250px] truncate hover:text-fill-default hover:underline' : 'flex-1 truncate'}
      >
        {name || t('menuAppHeader.defaultNewPageName')}
      </span>
    </div>
  );
}

export default Item;

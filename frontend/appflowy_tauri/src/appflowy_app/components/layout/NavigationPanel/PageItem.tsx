import { DocumentSvg } from '../../_shared/svg/DocumentSvg';
import { BoardSvg } from '../../_shared/svg/BoardSvg';
import { GridSvg } from '../../_shared/svg/GridSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { NavItemOptionsPopup } from './NavItemOptionsPopup';
import { IPage } from '$app_reducers/pages/slice';
import { Button } from '../../_shared/Button';
import { usePageEvents } from './PageItem.hooks';
import { RenamePopup } from './RenamePopup';
import { ViewLayoutPB } from '@/services/backend';
import { useEffect, useRef, useState } from 'react';
import { PAGE_ITEM_HEIGHT } from '../../_shared/constants';

export const PageItem = ({ page, onPageClick }: { page: IPage; onPageClick: () => void }) => {
  const {
    showPageOptions,
    onPageOptionsClick,
    showRenamePopup,
    startPageRename,
    changePageTitle,
    deletePage,
    duplicatePage,
    closePopup,
    closeRenamePopup,
    activePageId,
  } = usePageEvents(page);

  const el = useRef<HTMLDivElement>(null);

  const [popupY, setPopupY] = useState(0);

  useEffect(() => {
    if (el.current) {
      const { top } = el.current.getBoundingClientRect();
      setPopupY(top);
    }
  }, [showPageOptions, showRenamePopup]);

  return (
    <div ref={el}>
      <div
        onClick={() => onPageClick()}
        className={`flex cursor-pointer items-center justify-between rounded-lg pl-8 pr-4 hover:bg-surface-2 ${
          activePageId === page.id ? 'bg-surface-2' : ''
        }`}
        style={{ height: PAGE_ITEM_HEIGHT }}
      >
        <button className={'flex min-w-0 flex-1 items-center'}>
          <i className={'ml-1 mr-1 h-[16px] w-[16px]'}>
            {page.pageType === ViewLayoutPB.Document && <DocumentSvg></DocumentSvg>}
            {page.pageType === ViewLayoutPB.Board && <BoardSvg></BoardSvg>}
            {page.pageType === ViewLayoutPB.Grid && <GridSvg></GridSvg>}
          </i>
          <span className={'ml-2 min-w-0 flex-1 overflow-hidden overflow-ellipsis whitespace-nowrap text-left'}>
            {page.title}
          </span>
        </button>
        <div className={'flex items-center'}>
          <Button size={'box-small-transparent'} onClick={() => onPageOptionsClick()}>
            <Details2Svg></Details2Svg>
          </Button>
        </div>
      </div>
      {showPageOptions && (
        <NavItemOptionsPopup
          onRenameClick={() => startPageRename()}
          onDeleteClick={() => deletePage()}
          onDuplicateClick={() => duplicatePage()}
          onClose={() => closePopup()}
          top={popupY - 124 + 40}
        ></NavItemOptionsPopup>
      )}
      {showRenamePopup && (
        <RenamePopup
          value={page.title}
          onChange={(newTitle) => changePageTitle(newTitle)}
          onClose={closeRenamePopup}
          top={popupY - 124 + 40}
        ></RenamePopup>
      )}
    </div>
  );
};

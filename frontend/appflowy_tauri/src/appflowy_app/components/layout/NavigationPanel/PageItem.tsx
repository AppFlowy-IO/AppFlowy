import { DocumentSvg } from '../../_shared/svg/DocumentSvg';
import { BoardSvg } from '../../_shared/svg/BoardSvg';
import { GridSvg } from '../../_shared/svg/GridSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { NavItemOptionsPopup } from './NavItemOptionsPopup';
import { IPage } from '../../../stores/reducers/pages/slice';
import { Button } from '../../_shared/Button';
import { usePageEvents } from './PageItem.hooks';
import { RenamePopup } from './RenamePopup';
import { ViewLayoutTypePB } from '../../../../services/backend';
import { useEffect, useRef } from 'react';

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
    setOffsetTop,
  } = usePageEvents(page);

  const el = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setOffsetTop(el.current?.offsetTop || 0);
  }, [el]);

  return (
    <div className={'relative'} ref={el}>
      <div
        onClick={() => onPageClick()}
        className={`flex cursor-pointer items-center justify-between rounded-lg py-2 pl-8 pr-4 hover:bg-surface-2 ${
          activePageId === page.id ? 'bg-surface-2' : ''
        }`}
      >
        <button className={'flex min-w-0 flex-1 items-center'}>
          <i className={'ml-1 mr-1 h-[16px] w-[16px]'}>
            {page.pageType === ViewLayoutTypePB.Document && <DocumentSvg></DocumentSvg>}
            {page.pageType === ViewLayoutTypePB.Board && <BoardSvg></BoardSvg>}
            {page.pageType === ViewLayoutTypePB.Grid && <GridSvg></GridSvg>}
          </i>
          <span className={'ml-2 min-w-0 flex-1 overflow-hidden overflow-ellipsis whitespace-nowrap text-left'}>
            {page.title}
          </span>
        </button>
        <div className={'relative flex items-center'}>
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
        ></NavItemOptionsPopup>
      )}
      {showRenamePopup && (
        <RenamePopup
          value={page.title}
          onChange={(newTitle) => changePageTitle(newTitle)}
          onClose={closeRenamePopup}
        ></RenamePopup>
      )}
    </div>
  );
};

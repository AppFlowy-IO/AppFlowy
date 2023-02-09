import { DocumentSvg } from '../../_shared/svg/DocumentSvg';
import { BoardSvg } from '../../_shared/svg/BoardSvg';
import { GridSvg } from '../../_shared/svg/GridSvg';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { NavItemOptionsPopup } from './NavItemOptionsPopup';
import { IPage } from '../../../redux/pages/slice';
import { Button } from '../../_shared/Button';
import { usePageEvents } from './PageItem.hooks';
import { RenamePopup } from './RenamePopup';

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
  } = usePageEvents(page);

  return (
    <div className={'relative'}>
      <div
        onClick={() => onPageClick()}
        className={'flex cursor-pointer items-center justify-between rounded-lg py-2 pl-8 pr-4 hover:bg-surface-2 '}
      >
        <div className={'flex min-w-0 flex-1 items-center'}>
          <div className={'ml-1 mr-1 h-[16px] w-[16px]'}>
            {page.pageType === 'document' && <DocumentSvg></DocumentSvg>}
            {page.pageType === 'board' && <BoardSvg></BoardSvg>}
            {page.pageType === 'grid' && <GridSvg></GridSvg>}
          </div>
          <span className={'ml-2 min-w-0 flex-1 overflow-hidden overflow-ellipsis whitespace-nowrap'}>{page.title}</span>
        </div>
        <div className={'relative flex items-center'}>
          <Button size={'box-small-transparent'} onClick={() => onPageOptionsClick()}>
            <Details2Svg></Details2Svg>
          </Button>
          {showPageOptions && (
            <NavItemOptionsPopup
              onRenameClick={() => startPageRename()}
              onDeleteClick={() => deletePage()}
              onDuplicateClick={() => duplicatePage()}
              onClose={() => closePopup()}
            ></NavItemOptionsPopup>
          )}
        </div>
      </div>
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

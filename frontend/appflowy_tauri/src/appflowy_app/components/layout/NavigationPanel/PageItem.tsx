import { DocumentSvg } from '../../_shared/DocumentSvg';
import { BoardSvg } from '../../_shared/BoardSvg';
import { GridSvg } from '../../_shared/GridSvg';
import { Details2Svg } from '../../_shared/Details2Svg';
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
        className={'pl-8 pr-4 py-2 cursor-pointer flex items-center justify-between rounded-lg hover:bg-surface-2 '}
      >
        <div className={'flex items-center flex-1 min-w-0'}>
          <div className={'ml-1 w-[16px] h-[16px] mr-1'}>
            {page.pageType === 'document' && <DocumentSvg></DocumentSvg>}
            {page.pageType === 'board' && <BoardSvg></BoardSvg>}
            {page.pageType === 'grid' && <GridSvg></GridSvg>}
          </div>
          <span className={'whitespace-nowrap overflow-ellipsis overflow-hidden min-w-0 flex-1 ml-2'}>{page.title}</span>
        </div>
        <div className={'flex items-center relative'}>
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

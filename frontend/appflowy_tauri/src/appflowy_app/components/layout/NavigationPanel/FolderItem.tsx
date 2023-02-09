import { Details2Svg } from '../../_shared/svg/Details2Svg';
import AddSvg from '../../_shared/svg/AddSvg';
import { NavItemOptionsPopup } from './NavItemOptionsPopup';
import { NewPagePopup } from './NewPagePopup';
import { IFolder } from '../../../redux/folders/slice';
import { useFolderEvents } from './FolderItem.hooks';
import { IPage } from '../../../redux/pages/slice';
import { PageItem } from './PageItem';
import { Button } from '../../_shared/Button';
import { RenamePopup } from './RenamePopup';

export const FolderItem = ({
  folder,
  pages,
  onPageClick,
}: {
  folder: IFolder;
  pages: IPage[];
  onPageClick: (page: IPage) => void;
}) => {
  const {
    showPages,
    onFolderNameClick,
    showFolderOptions,
    onFolderOptionsClick,
    showNewPageOptions,
    onNewPageClick,

    showRenamePopup,
    startFolderRename,
    changeFolderTitle,
    closeRenamePopup,
    deleteFolder,
    duplicateFolder,

    onAddNewDocumentPage,
    onAddNewBoardPage,
    onAddNewGridPage,

    closePopup,
  } = useFolderEvents(folder);

  return (
    <div className={'relative my-2'}>
      <div
        onClick={() => onFolderNameClick()}
        className={'flex cursor-pointer items-center justify-between rounded-lg px-4 py-2 hover:bg-surface-2'}
      >
        <div className={'flex min-w-0 flex-1 items-center'}>
          <div className={`mr-2 transition-transform duration-500 ${showPages && 'rotate-180'}`}>
            <img className={''} src={'/images/home/drop_down_show.svg'} alt={''} />
          </div>
          <span className={'min-w-0 flex-1 overflow-hidden overflow-ellipsis whitespace-nowrap'}>{folder.title}</span>
        </div>
        <div className={'relative flex items-center'}>
          <Button size={'box-small-transparent'} onClick={() => onFolderOptionsClick()}>
            <Details2Svg></Details2Svg>
          </Button>
          <Button size={'box-small-transparent'} onClick={() => onNewPageClick()}>
            <AddSvg></AddSvg>
          </Button>

          {showFolderOptions && (
            <NavItemOptionsPopup
              onRenameClick={() => startFolderRename()}
              onDeleteClick={() => deleteFolder()}
              onDuplicateClick={() => duplicateFolder()}
              onClose={() => closePopup()}
            ></NavItemOptionsPopup>
          )}
          {showNewPageOptions && (
            <NewPagePopup
              onDocumentClick={() => onAddNewDocumentPage()}
              onBoardClick={() => onAddNewBoardPage()}
              onGridClick={() => onAddNewGridPage()}
              onClose={() => closePopup()}
            ></NewPagePopup>
          )}
        </div>
      </div>
      {showRenamePopup && (
        <RenamePopup
          value={folder.title}
          onChange={(newTitle) => changeFolderTitle(newTitle)}
          onClose={closeRenamePopup}
        ></RenamePopup>
      )}
      {showPages &&
        pages.map((page, index) => <PageItem key={index} page={page} onPageClick={() => onPageClick(page)}></PageItem>)}
    </div>
  );
};

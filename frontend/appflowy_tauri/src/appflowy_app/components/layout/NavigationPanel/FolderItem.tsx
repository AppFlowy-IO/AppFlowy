import { Details2Svg } from '../../_shared/svg/Details2Svg';
import AddSvg from '../../_shared/svg/AddSvg';
import { NavItemOptionsPopup } from './NavItemOptionsPopup';
import { NewPagePopup } from './NewPagePopup';
import { IFolder } from '$app_reducers/folders/slice';
import { useFolderEvents } from './FolderItem.hooks';
import { IPage } from '$app_reducers/pages/slice';
import { PageItem } from './PageItem';
import { Button } from '../../_shared/Button';
import { RenamePopup } from './RenamePopup';
import { useEffect, useRef, useState } from 'react';
import { DropDownShowSvg } from '../../_shared/svg/DropDownShowSvg';
import { ANIMATION_DURATION } from '../../_shared/constants';

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
    folderHeight,
  } = useFolderEvents(folder, pages);

  const [popupY, setPopupY] = useState(0);

  const el = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (el.current) {
      const { top } = el.current.getBoundingClientRect();
      setPopupY(top);
    }
  }, [showFolderOptions, showNewPageOptions, showRenamePopup]);

  return (
    <div ref={el}>
      <div
        className={`my-2 overflow-hidden transition-all`}
        style={{ height: folderHeight, transitionDuration: `${ANIMATION_DURATION}ms` }}
      >
        <div
          onClick={() => onFolderNameClick()}
          className={'flex cursor-pointer items-center justify-between rounded-lg px-4 py-2 hover:bg-surface-2'}
        >
          <button className={'flex min-w-0 flex-1 items-center'}>
            <i className={`mr-2 h-5 w-5 transition-transform duration-500 ${showPages && 'rotate-180'}`}>
              {pages.length > 0 && <DropDownShowSvg></DropDownShowSvg>}
            </i>
            <span className={'min-w-0 flex-1 overflow-hidden overflow-ellipsis whitespace-nowrap text-left'}>
              {folder.title}
            </span>
          </button>
          <div className={'flex items-center'}>
            <Button size={'box-small-transparent'} onClick={() => onFolderOptionsClick()}>
              <Details2Svg></Details2Svg>
            </Button>
            <Button size={'box-small-transparent'} onClick={() => onNewPageClick()}>
              <AddSvg></AddSvg>
            </Button>
          </div>
        </div>

        {pages.map((page, index) => (
          <PageItem key={index} page={page} onPageClick={() => onPageClick(page)}></PageItem>
        ))}
      </div>
      {showFolderOptions && (
        <NavItemOptionsPopup
          onRenameClick={() => startFolderRename()}
          onDeleteClick={() => deleteFolder()}
          onDuplicateClick={() => duplicateFolder()}
          onClose={() => closePopup()}
          top={popupY - 124 + 40}
        ></NavItemOptionsPopup>
      )}
      {showNewPageOptions && (
        <NewPagePopup
          onDocumentClick={() => onAddNewDocumentPage()}
          onBoardClick={() => onAddNewBoardPage()}
          onGridClick={() => onAddNewGridPage()}
          onClose={() => closePopup()}
          top={popupY - 124 + 40}
        ></NewPagePopup>
      )}
      {showRenamePopup && (
        <RenamePopup
          value={folder.title}
          onChange={(newTitle) => changeFolderTitle(newTitle)}
          onClose={closeRenamePopup}
          top={popupY - 124 + 40}
        ></RenamePopup>
      )}
    </div>
  );
};
